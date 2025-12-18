#!/bin/bash

# Script de déploiement pour VM de production
# Usage: ./deploy.sh [IMAGE_TAG]

set -e

IMAGE_TAG=${1:-"latest"}
APP_NAME="push-to-prod"
APP_DIR="/opt/$APP_NAME"
SERVICE_NAME="$APP_NAME"
BACKUP_DIR="/opt/$APP_NAME-backup"

echo "🚀 Début du déploiement de $APP_NAME"
echo "📦 Version: $IMAGE_TAG"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

rollback() {
    log "❌ Erreur détectée, rollback en cours..."
    if [ -d "$BACKUP_DIR" ]; then
        sudo systemctl stop $SERVICE_NAME || true
        sudo rm -rf $APP_DIR
        sudo mv $BACKUP_DIR $APP_DIR
        sudo systemctl start $SERVICE_NAME
        log "🔄 Rollback effectué"
    fi
    exit 1
}

trap rollback ERR

if ! command -v docker &> /dev/null; then
    log "📦 Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
fi

if [ -d "$APP_DIR" ]; then
    log "💾 Sauvegarde de la version actuelle..."
    sudo rm -rf $BACKUP_DIR
    sudo cp -r $APP_DIR $BACKUP_DIR
fi

sudo mkdir -p $APP_DIR
cd $APP_DIR

log "⏹Arrêt du service existant..."
sudo systemctl stop $SERVICE_NAME || true

log "Téléchargement de l'image Docker..."
sudo docker pull ghcr.io/$GITHUB_REPOSITORY:$IMAGE_TAG || sudo docker pull $IMAGE_TAG

log "🧹 Nettoyage des anciens conteneurs..."
sudo docker stop $APP_NAME || true
sudo docker rm $APP_NAME || true

log "🚀 Démarrage du nouveau conteneur..."
sudo docker run -d \
    --name $APP_NAME \
    --restart unless-stopped \
    -p 3000:3000 \
    -e NODE_ENV=production \
    --health-cmd="curl -f http://localhost:3000/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    ghcr.io/$GITHUB_REPOSITORY:$IMAGE_TAG || sudo docker run -d \
    --name $APP_NAME \
    --restart unless-stopped \
    -p 3000:3000 \
    -e NODE_ENV=production \
    $IMAGE_TAG

log "Configuration du service systemd..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=$APP_NAME Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/bin/docker start $APP_NAME
ExecStop=/usr/bin/docker stop $APP_NAME
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

log "Test de santé de l'application..."
for i in {1..10}; do
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log "Application démarrée avec succès!"
        break
    fi
    if [ $i -eq 10 ]; then
        log "Échec du test de santé après 10 tentatives"
        exit 1
    fi
    log "⏳ Tentative $i/10, attente..."
    sleep 5
done

log "🧹 Nettoyage des anciennes images Docker..."
sudo docker system prune -f

if [ -d "$BACKUP_DIR" ]; then
    sudo rm -rf $BACKUP_DIR
    log "Sauvegarde supprimée"
fi

log "Déploiement terminé avec succès!"
log "Application accessible sur http://$(hostname -I | awk '{print $1}'):3000"

log "📋 Logs récents de l'application:"
sudo docker logs --tail 20 $APP_NAME