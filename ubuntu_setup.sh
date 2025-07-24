#!/bin/bash

# Ubuntu Setup Script
# Bu script Ubuntu yüklədikdən sonra lazımı proqramları avtomatik yükləyir

echo "🚀 Ubuntu Setup Script başlayır..."
echo "========================================"

# Sistem rənglər
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funksiya: Uğurlu mesaj
success_msg() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Funksiya: Xəta mesajı
error_msg() {
    echo -e "${RED}❌ $1${NC}"
}

# Funksiya: Info mesajı
info_msg() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Funksiya: Warning mesajı
warning_msg() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Sistem yeniləmə
info_msg "Sistem yenilənir..."
sudo apt update && sudo apt upgrade -y
success_msg "Sistem yeniləndi"

# 2. Əsas paketlər
info_msg "Əsas paketlər yüklənir..."
sudo apt install -y curl wget git vim software-properties-common apt-transport-https ca-certificates gnupg lsb-release build-essential
success_msg "Əsas paketlər yükləndi"

# 3. Docker yükləmə
info_msg "Docker yüklənir..."
# Docker-in əvvəlki versiyalarını sil
sudo apt remove -y docker docker-engine docker.io containerd runc

# Docker-in rəsmi GPG açarını əlavə et
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository əlavə et
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker Engine yüklə
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker-i sudo olmadan işlətmək üçün
sudo groupadd docker
sudo usermod -aG docker $USER

# Docker-i avtomatik başlatmaq üçün
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

success_msg "Docker yükləndi və konfiqurasiya edildi"

# 4. Google Chrome
info_msg "Google Chrome yüklənir..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt update
sudo apt install -y google-chrome-stable
success_msg "Google Chrome yükləndi"

# 5. Visual Studio Code
info_msg "Visual Studio Code yüklənir..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code
success_msg "Visual Studio Code yükləndi"

# 6. Snap paketlər
info_msg "Snap paketləri yüklənir..."

# Discord
sudo snap install discord

# Postman
sudo snap install postman

# Telegram Desktop
sudo snap install telegram-desktop

# Zoom
sudo snap install zoom-client

# OBS Studio
sudo snap install obs-studio

# Steam
sudo snap install steam

# Notion
sudo snap install notion-snap-reborn

success_msg "Snap paketləri yükləndi"

# 7. Slack
info_msg "Slack yüklənir..."
wget -O slack.deb https://downloads.slack-edge.com/releases/linux/4.29.149/prod/x64/slack-desktop-4.29.149-amd64.deb
sudo dpkg -i slack.deb
sudo apt-get install -f -y
rm slack.deb
success_msg "Slack yükləndi"

# 8. DBeaver Community Edition
info_msg "DBeaver yüklənir..."
wget -O dbeaver.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
sudo dpkg -i dbeaver.deb
sudo apt-get install -f -y
rm dbeaver.deb
success_msg "DBeaver yükləndi"

# 9. Əlavə faydalı proqramlar
info_msg "Əlavə faydalı proqramlar yüklənir..."
sudo apt install -y \
    htop \
    tree \
    neofetch \
    git \
    curl \
    wget \
    vim \
    nano \
    unzip \
    zip \
    rar \
    unrar \
    vlc \
    gimp \
    firefox \
    thunderbird

success_msg "Əlavə proqramlar yükləndi"

# 10. Sistem təmizliyi
info_msg "Sistem təmizlənir..."
sudo apt autoremove -y
sudo apt autoclean
success_msg "Sistem təmizləndi"

echo ""
echo "========================================"
echo -e "${GREEN}🎉 Ubuntu setup tamamlandı!${NC}"
echo ""
warning_msg "Qeyd: Docker-i sudo olmadan işlətmək üçün sistemdən çıxıb yenidən daxil olun və ya aşağıdakı əmri yerinə yetirin:"
echo -e "${YELLOW}newgrp docker${NC}"
echo ""
info_msg "Yüklənən proqramlar:"
echo "✅ Docker & Docker Compose"
echo "✅ Google Chrome"
echo "✅ Visual Studio Code"
echo "✅ Discord"
echo "✅ Postman"
echo "✅ Telegram Desktop"
echo "✅ Zoom"
echo "✅ OBS Studio"
echo "✅ Steam"
echo "✅ Notion"
echo "✅ Slack"
echo "✅ DBeaver"
echo "✅ Digər faydalı alətlər"
echo ""
success_msg "Sisteminiz hazırdır! 🚀"
