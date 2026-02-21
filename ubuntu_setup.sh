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

# Funksiya: Bəli/Xeyr təsdiqi (default: No)
confirm() {
    local prompt="$1"
    local reply
    read -r -p "${prompt} [y/N]: " reply
    [[ "$reply" =~ ^([yY]([eE][sS])?)$ ]]
}

maybe_run() {
    local title="$1"
    shift
    if confirm "$title"; then
        "$@"
    else
        warning_msg "Keçildi: $title"
        return 0
    fi
}

# 1. Sistem yeniləmə
info_msg "Sistem yenilənir..."
if confirm "Mərhələ: Sistem update + upgrade edilsin?"; then
    sudo apt update && sudo apt upgrade -y && success_msg "Sistem yeniləndi" || warning_msg "Sistem yenilənməsi uğursuz oldu"
else
    warning_msg "Keçildi: Sistem yeniləmə"
fi

# 2. Əsas paketlər
info_msg "Əsas paketlər yüklənir..."
if confirm "Mərhələ: Əsas paketləri yüklə? (curl, wget, git, vim, ...)"; then
    sudo apt install -y curl wget git vim software-properties-common apt-transport-https ca-certificates gnupg lsb-release build-essential \
        && success_msg "Əsas paketlər yükləndi" \
        || warning_msg "Əsas paketlərin bəziləri yüklənmədi"
else
    warning_msg "Keçildi: Əsas paketlər"
fi

# 3. Docker yükləmə
info_msg "Docker yüklənir..."
if confirm "Mərhələ: Docker yüklə və konfiqurasiya et?"; then
    sudo apt remove -y docker docker-engine docker.io containerd runc

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    if sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        sudo groupadd docker
        sudo usermod -aG docker $USER
        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
        success_msg "Docker yükləndi və konfiqurasiya edildi"
    else
        warning_msg "Docker yüklənmədi"
    fi
else
    warning_msg "Keçildi: Docker"
fi

# 4. Google Chrome
info_msg "Google Chrome yüklənir..."
if confirm "Yüklə: Google Chrome?"; then
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt update
    sudo apt install -y google-chrome-stable && success_msg "Google Chrome yükləndi" || warning_msg "Google Chrome yüklənmədi"
else
    warning_msg "Keçildi: Google Chrome"
fi

# 5. Visual Studio Code
info_msg "Visual Studio Code yüklənir..."
if confirm "Yüklə: Visual Studio Code?"; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt update
    sudo apt install -y code && success_msg "Visual Studio Code yükləndi" || warning_msg "Visual Studio Code yüklənmədi"
else
    warning_msg "Keçildi: Visual Studio Code"
fi

# 6. Snap paketlər
info_msg "Snap paketləri yüklənir..."
if confirm "Mərhələ: Snap paketlərini yüklə? (Discord, Postman, Telegram, Zoom, OBS, Steam, Notion)"; then
    sudo snap install discord || warning_msg "Discord yüklənmədi"
    sudo snap install postman || warning_msg "Postman yüklənmədi"
    sudo snap install telegram-desktop || warning_msg "Telegram yüklənmədi"
    sudo snap install zoom-client || warning_msg "Zoom yüklənmədi"
    sudo snap install obs-studio || warning_msg "OBS Studio yüklənmədi"
    sudo snap install steam || warning_msg "Steam yüklənmədi"
    sudo snap install notion-snap-reborn || warning_msg "Notion yüklənmədi"
    success_msg "Snap paketləri addımı tamamlandı"
else
    warning_msg "Keçildi: Snap paketləri"
fi

# 7. Slack
info_msg "Slack yüklənir..."
if confirm "Yüklə: Slack?"; then
    wget -O slack.deb https://downloads.slack-edge.com/releases/linux/4.29.149/prod/x64/slack-desktop-4.29.149-amd64.deb
    sudo dpkg -i slack.deb
    sudo apt-get install -f -y
    rm slack.deb
    success_msg "Slack yükləndi"
else
    warning_msg "Keçildi: Slack"
fi

# 8. DBeaver Community Edition
info_msg "DBeaver yüklənir..."
if confirm "Yüklə: DBeaver?"; then
    wget -O dbeaver.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
    sudo dpkg -i dbeaver.deb
    sudo apt-get install -f -y
    rm dbeaver.deb
    success_msg "DBeaver yükləndi"
else
    warning_msg "Keçildi: DBeaver"
fi

# 9. GitHub SSH key konfiqurasiyası
info_msg "GitHub SSH key konfiqurasiyası..."

if ! confirm "GitHub üçün SSH key yaradılsın və konfiqurasiya edilsin?"; then
    warning_msg "GitHub SSH key addımı keçildi."
else

# İstifadəçidən email al
echo ""
echo -e "${YELLOW}GitHub SSH key yaratmaq üçün email lazımdır.${NC}"
read -r -p "GitHub email adresinizi daxil edin: " github_email

if [ -n "$github_email" ]; then
    # İstifadəçi adını da al
    read -r -p "GitHub istifadəçi adınızı daxil edin: " github_username
    
    # Git global konfiqurasiya
    if [ -n "$github_username" ]; then
        git config --global user.name "$github_username"
        git config --global user.email "$github_email"
        success_msg "Git konfiqurasiya edildi"
    fi
    
    mkdir -p ~/.ssh

    key_path="$HOME/.ssh/id_ed25519"
    if [ -f "$key_path" ] || [ -f "${key_path}.pub" ]; then
        warning_msg "Mövcud SSH key tapıldı: $key_path"
        if ! confirm "Üzərinə yazılsın?"; then
            key_path="$HOME/.ssh/id_ed25519_github"
            if [ -f "$key_path" ] || [ -f "${key_path}.pub" ]; then
                key_path="$HOME/.ssh/id_ed25519_github_$(date +%Y%m%d%H%M%S)"
            fi
            info_msg "Yeni key faylı istifadə olunacaq: $key_path"
        fi
    fi

    if ! confirm "İndi SSH key yaradaq?"; then
        warning_msg "SSH key yaradılmadı."
    else
        # SSH key yarad
        ssh-keygen -t ed25519 -C "$github_email" -f "$key_path" -N ""
    
    # SSH agent-i başlat
        eval "$(ssh-agent -s)"
    
    # SSH key-i agent-ə əlavə et
        ssh-add "$key_path"
    
    # SSH config faylı yarat
        ssh_config="$HOME/.ssh/config"
        touch "$ssh_config"
        chmod 600 "$ssh_config" 2>/dev/null || true
        if ! grep -qE '^Host[[:space:]]+github\.com$' "$ssh_config" 2>/dev/null; then
            cat >> "$ssh_config" << EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $key_path
EOF
        else
            info_msg "~/.ssh/config içində github.com artıq mövcuddur; dəyişdirilmədi."
        fi
    
    # Public key-i göstər
    echo ""
    echo -e "${GREEN}SSH Public Key (GitHub-a əlavə etmək üçün):${NC}"
    echo "========================================"
        cat "${key_path}.pub"
    echo "========================================"
    echo ""
    echo -e "${YELLOW}Bu key-i kopyalayın və GitHub-ın SSH keys bölməsinə əlavə edin:${NC}"
    echo -e "${BLUE}1. GitHub.com-a daxil olun${NC}"
    echo -e "${BLUE}2. Settings > SSH and GPG keys-ə gedin${NC}"
    echo -e "${BLUE}3. 'New SSH key' düyməsini basın${NC}"
    echo -e "${BLUE}4. Yuxarıdakı key-i yapışdırın${NC}"
    echo ""
    echo -e "${YELLOW}Davam etmək üçün Enter basın...${NC}"
        read -r -p ""
    
    success_msg "SSH key yaradıldı və konfiqurasiya edildi"
    fi
else
    warning_msg "Email daxil edilmədi. SSH key yaradılmadı."
fi

fi

# 10. Zsh və Oh My Zsh konfiqurasiyası
info_msg "Zsh və Oh My Zsh yüklənir..."
if confirm "Mərhələ: Zsh + Oh My Zsh + plugin-lər?"; then
    sudo apt install -y zsh || warning_msg "zsh yüklənmədi"
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || warning_msg "zsh-autosuggestions clone olmadı"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || warning_msg "zsh-syntax-highlighting clone olmadı"

    if [ -f ~/.zshrc ]; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
    fi

    if confirm "Zsh default shell edilsin? (chsh)"; then
        chsh -s $(which zsh)
    else
        warning_msg "Keçildi: chsh"
    fi

    success_msg "Zsh və Oh My Zsh addımı tamamlandı"
else
    warning_msg "Keçildi: Zsh + Oh My Zsh"
fi

# 11. Əlavə faydalı proqramlar
info_msg "Əlavə faydalı proqramlar yüklənir..."
if confirm "Mərhələ: Əlavə proqramları yüklə? (htop, tree, vlc, gimp, ...)"; then
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
        thunderbird \
        && success_msg "Əlavə proqramlar addımı tamamlandı" \
        || warning_msg "Bəzi əlavə proqramlar yüklənmədi"
else
    warning_msg "Keçildi: Əlavə proqramlar"
fi

# 12. Sistem təmizliyi
info_msg "Sistem təmizlənir..."
if confirm "Sistem təmizliyi edilsin? (autoremove/autoclean)"; then
    sudo apt autoremove -y
    sudo apt autoclean
    success_msg "Sistem təmizləndi"
else
    warning_msg "Keçildi: sistem təmizliyi"
fi

echo ""
echo "========================================"
echo -e "${GREEN}🎉 Ubuntu setup tamamlandı!${NC}"
echo ""
warning_msg "Qeyd: Docker-i sudo olmadan işlətmək üçün sistemdən çıxıb yenidən daxil olun və ya aşağıdakı əmri yerinə yetirin:"
echo -e "${YELLOW}newgrp docker${NC}"
echo ""
warning_msg "Zsh-i default shell olaraq istifadə etmək üçün sistemdən çıxıb yenidən daxil olun və ya yeni terminal açın."
echo ""
info_msg "Seçilən/yüklənə bilən proqramlar:"
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
echo "✅ GitHub SSH key konfiqurasiyası"
echo "✅ Git global konfiqurasiya"
echo "✅ Zsh + Oh My Zsh + Plugins (autosuggestions, syntax-highlighting)"
echo "✅ Digər faydalı alətlər"
echo ""
info_msg "Zsh özəllikləri:"
echo "🔥 Agnoster theme"
echo "🔥 Auto-suggestions (sağ ox ilə qəbul et)"
echo "🔥 Syntax highlighting (doğru əmrlər yaşıl, səhv əmrlər qırmızı)"
echo "🔥 Git integration"
echo ""
info_msg "GitHub SSH key test etmək üçün:"
echo "🔑 ssh -T git@github.com"
echo ""
success_msg "Sisteminiz hazırdır! 🚀"
