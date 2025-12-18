#!/bin/bash

# Script de configuration initiale du serveur de production

set -e

APP_USER="app"
APP_NAME="push-to-prod"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Configuration initiale du serveur de production"

log "Mise à jour du système..."
sudo apt-get update
sudo apt-get upgrade -y

log "Installation des outils de base..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    htop \
    ufw \
    fail2ban \
    unattended-upgrades

log "🔥 Configuration du firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000/tcp
sudo ufw --force enable

if ! command -v docker &> /dev/null; then
    log "Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    rm get-docker.sh
fi

if ! id "$APP_USER" &>/dev/null; then
    log "Création de l'utilisateur $APP_USER..."
    sudo useradd -m -s /bin/bash $APP_USER
    sudo usermod -aG docker $APP_USER
fi

log "Configuration des mises à jour automatiques..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "Configuration de fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

log "📊 Installation d'outils de monitoring..."
sudo apt-get install -y htop iotop nethogs

log "Configuration de la rotation des logs..."
sudo tee /etc/logrotate.d/$APP_NAME > /dev/null <<EOF
/var/log/$APP_NAME/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 $APP_USER $APP_USER
    postrotate
        docker restart $APP_NAME 2>/dev/null || true
    endscript
}
EOF

sudo mkdir -p /var/log/$APP_NAME
sudo chown $APP_USER:$APP_USER /var/log/$APP_NAME

log "Installation du script de surveillance..."
sudo tee /usr/local/bin/monitor-$APP_NAME.sh > /dev/null <<'EOF'
#!/bin/bash

APP_NAME="push-to-prod"
LOG_FILE="/var/log/$APP_NAME/monitor.log"

check_health() {
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "[$(date)] OK: Application healthy" >> $LOG_FILE
        return 0
    else
        echo "[$(date)] ERROR: Application not responding" >> $LOG_FILE
        return 1
    fi
}

restart_if_unhealthy() {
    if ! check_health; then
        echo "[$(date)] Restarting $APP_NAME container..." >> $LOG_FILE
        docker restart $APP_NAME
        sleep 30
        if check_health; then
            echo "[$(date)] Restart successful" >> $LOG_FILE
        else
            echo "[$(date)] Restart failed, manual intervention required" >> $LOG_FILE
        fi
    fi
}

restart_if_unhealthy
EOF

sudo chmod +x /usr/local/bin/monitor-$APP_NAME.sh

(sudo crontab -l 2>/dev/null || echo "") | grep -v "monitor-$APP_NAME" | sudo crontab -
echo "*/5 * * * * /usr/local/bin/monitor-$APP_NAME.sh" | sudo crontab -

log "Configuration du serveur terminée!"