#!/bin/bash

# Script de déploiement simple pour VM (sans sudo)
set -e

IMAGE_TAG=${1:-"latest"}
APP_NAME="push-to-prod"

echo "Début du déploiement de $APP_NAME"
echo "Version: $IMAGE_TAG"

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

echo "⏹Arrêt de l'ancien conteneur..."
docker stop $APP_NAME 2>/dev/null || true
docker rm $APP_NAME 2>/dev/null || true

echo "Téléchargement de l'image..."
docker pull ghcr.io/armanceau/push-to-prod:main 2>/dev/null || echo "Image non trouvée, utilisation locale"

echo "Démarrage du nouveau conteneur..."
docker run -d \
    --name $APP_NAME \
    --restart unless-stopped \
    -p 3000:3000 \
    -e NODE_ENV=production \
    ghcr.io/armanceau/push-to-prod:main 2>/dev/null || \
docker run -d \
    --name $APP_NAME \
    --restart unless-stopped \
    -p 3000:3000 \
    -e NODE_ENV=production \
    node:18-alpine sh -c "cd /app && npm start"

echo "Attente du démarrage..."
sleep 10

echo "🏥 Test de santé..."
for i in {1..6}; do
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Application démarrée avec succès!"
        echo "🌐 Accessible sur http://$(curl -s ifconfig.me):3000"
        exit 0
    fi
    echo "Tentative $i/6..."
    sleep 5
done

echo "❌ Échec du démarrage"
exit 1