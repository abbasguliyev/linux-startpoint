#!/usr/bin/env bash

# Fedora Setup Script
# Bu script Fedora yüklədikdən sonra lazımı proqramları avtomatik yükləyir

echo "🚀 Fedora Setup Script başlayır..."
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

# Root kimi işlətməyin (usermod/chsh/flatpak --user üçün)
if [ "${EUID}" -eq 0 ]; then
    error_msg "Bu script-i root kimi yox, normal istifadəçi kimi işlədin (sudo içəridə istifadə olunur)."
    exit 1
fi

# Fedora yoxlaması (sərt deyil)
if [ -r /etc/os-release ]; then
    . /etc/os-release
    if [ "${ID:-}" != "fedora" ]; then
        warning_msg "Bu script Fedora üçün yazılıb. Aşkarlanan distro: ${ID:-unknown}. Davam edilir..."
    fi
fi

# Sudo parolunu əvvəlcədən istə
sudo -v || exit 1

# 1. Sistem yeniləmə
info_msg "Sistem yenilənir..."
if maybe_run "Sistemi yeniləyək? (dnf upgrade)" sudo dnf upgrade -y --refresh; then
    success_msg "Sistem yeniləndi"
else
    error_msg "Sistem yenilənməsi uğursuz oldu"
fi

# 2. Əsas paketlər
info_msg "Əsas paketlər yüklənir..."
if confirm "Mərhələ: Əsas paketləri yüklə? (curl, wget, git, vim, ...)"; then
    if sudo dnf install -y \
        curl \
        wget \
        git \
        vim \
        ca-certificates \
        gnupg2 \
        dnf-plugins-core \
        util-linux-user; then
        success_msg "Əsas paketlər yükləndi"
    else
        warning_msg "Əsas paketlərin bəziləri yüklənmədi"
    fi
else
    warning_msg "Keçildi: Əsas paketlər"
fi

# Development tools (build-essential alternativi)
info_msg "Development Tools (gcc/make və s.) yüklənir..."
if confirm "Mərhələ: Development Tools yüklə?"; then
    if sudo dnf groupinstall -y "Development Tools"; then
        success_msg "Development Tools yükləndi"
    else
        warning_msg "Development Tools groupinstall alınmadı (qrup adı fərqli ola bilər). Minimal paketlər yoxlanır..."
        sudo dnf install -y gcc gcc-c++ make || warning_msg "gcc/g++/make yüklənmədi"
    fi
else
    warning_msg "Keçildi: Development Tools"
fi

# 3. Docker yükləmə
info_msg "Docker yüklənir..."

if confirm "Mərhələ: Docker yüklə və konfiqurasiya et?"; then

# Köhnə docker paketlərini sil
sudo dnf remove -y \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine >/dev/null 2>&1 || true

# Docker repo əlavə et
if sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo; then
    :
elif sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; then
    :
else
    warning_msg "Docker repo əlavə edilmədi (dnf-plugins-core yoxlanılsın)."
fi

# Docker yüklə
if sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    # Docker-i sudo olmadan işlətmək üçün
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"

    # Docker-i avtomatik başlatmaq üçün
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now containerd.service >/dev/null 2>&1 || true

    success_msg "Docker yükləndi və konfiqurasiya edildi"
else
    error_msg "Docker yüklənmədi"
fi
else
    warning_msg "Keçildi: Docker"
fi

# 4. Google Chrome
info_msg "Google Chrome yüklənir..."
if [ "$(uname -m)" = "x86_64" ]; then
    if confirm "Yüklə: Google Chrome?" && sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm; then
        success_msg "Google Chrome yükləndi"
    else
        warning_msg "Google Chrome yüklənmədi və ya keçildi"
    fi
else
    warning_msg "Google Chrome bu arxitekturda avtomatik qurulmur: $(uname -m)"
fi

# 4.1 Brave Browser
info_msg "Brave Browser yüklənir..."
if confirm "Yüklə: Brave Browser?" && sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc; then
    sudo tee /etc/yum.repos.d/brave-browser.repo >/dev/null << 'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

    if sudo dnf install -y brave-browser; then
        success_msg "Brave Browser yükləndi"
    else
        warning_msg "Brave Browser yüklənmədi"
    fi
else
    warning_msg "Brave GPG key import olunmadı"
fi

# 5. Visual Studio Code
info_msg "Visual Studio Code yüklənir..."
if confirm "Yüklə: Visual Studio Code?" && sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
    sudo tee /etc/yum.repos.d/vscode.repo >/dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    if sudo dnf install -y code; then
        success_msg "Visual Studio Code yükləndi"
    else
        error_msg "Visual Studio Code yüklənmədi"
    fi
else
    error_msg "Microsoft GPG key import olunmadı"
fi

# 6. Flatpak paketlər (Snap əvəzinə)
info_msg "Flatpak paketləri yüklənir..."

if confirm "Mərhələ: Flatpak + Flathub quraşdır?" && sudo dnf install -y flatpak; then
    info_msg "Flathub remote konfiqurasiya olunur (user scope)..."

    # Qeyd: Aşağıdakı flatpak install-lar `--user` istifadə edir, ona görə remote-da `--user` olmalıdır.
    if ! flatpak remotes --user --columns=name 2>/dev/null | grep -qx "flathub"; then
        if ! flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1; then
            warning_msg "Flathub remote əlavə edilmədi (şəbəkə/GPG problemi ola bilər)."
        fi
    fi

    # Bəzi sistemlərdə remote əlavə olsa belə disabled ola bilər
    flatpak remote-modify --user --enable flathub >/dev/null 2>&1 || true

    if flatpak remotes --user --columns=name 2>/dev/null | grep -qx "flathub" && flatpak remote-ls --user flathub >/dev/null 2>&1; then
        success_msg "Flathub remote hazırdır"

        if confirm "Mərhələ: Flatpak tətbiqlərini yüklə? (Discord, Postman, Telegram, Zoom, OBS, Steam, Notion, Slack, DBeaver)"; then
            flatpak install -y --noninteractive --user flathub com.discordapp.Discord || warning_msg "Discord flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub com.getpostman.Postman || warning_msg "Postman flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub org.telegram.desktop || warning_msg "Telegram flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub us.zoom.Zoom || warning_msg "Zoom flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub com.obsproject.Studio || warning_msg "OBS Studio flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub com.valvesoftware.Steam || warning_msg "Steam flatpak yüklənmədi"

            # Notion (Flathub-da tətbiq ID-si dəyişə bilər; bir neçə ehtimal yoxlanır)
            if flatpak install -y --noninteractive --user flathub io.github.mimbrero.Notion 2>/dev/null; then
                :
            elif flatpak install -y --noninteractive --user flathub io.github.janbar.notion 2>/dev/null; then
                :
            elif flatpak install -y --noninteractive --user flathub com.github.jaredallard.notion 2>/dev/null; then
                :
            else
                warning_msg "Notion flatpak tapılmadı (Flathub ID-si dəyişə bilər)."
            fi

            flatpak install -y --noninteractive --user flathub com.slack.Slack || warning_msg "Slack flatpak yüklənmədi"
            flatpak install -y --noninteractive --user flathub io.dbeaver.DBeaverCommunity || warning_msg "DBeaver flatpak yüklənmədi"
            success_msg "Flatpak tətbiqləri addımı tamamlandı"
        else
            warning_msg "Keçildi: Flatpak tətbiqləri"
        fi

        success_msg "Flatpak paketləri quraşdırma addımı tamamlandı"
    else
        error_msg "Flathub remote tapılmadı və ya əlçatan deyil. Flatpak tətbiqləri quraşdırılmadı. (Həll: 'flatpak remote-add --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo' və sonra 'flatpak remote-ls --user flathub')"
    fi
else
    error_msg "Flatpak yüklənmədi"
fi

# 9. GitHub SSH key konfiqurasiyası
info_msg "GitHub SSH key konfiqurasiyası..."

if ! confirm "GitHub üçün SSH key yaradılsın və konfiqurasiya edilsin?"; then
    warning_msg "GitHub SSH key addımı keçildi."
else

echo ""
echo -e "${YELLOW}GitHub SSH key yaratmaq üçün email lazımdır.${NC}"
read -r -p "GitHub email adresinizi daxil edin: " github_email

if [ -n "$github_email" ]; then
    read -r -p "GitHub istifadəçi adınızı daxil edin: " github_username

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
        ssh-keygen -t ed25519 -C "$github_email" -f "$key_path" -N ""

        eval "$(ssh-agent -s)"
        ssh-add "$key_path"

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

if confirm "Yüklə: zsh?" && sudo dnf install -y zsh; then
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended

    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || true

    if [ -f ~/.zshrc ]; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc || true
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc || true
    fi

    if confirm "Zsh default shell edilsin? (chsh)"; then
        chsh -s "$(command -v zsh)" || true
    else
        warning_msg "Keçildi: chsh"
    fi

    success_msg "Zsh və Oh My Zsh yükləndi və konfiqurasiya edildi"
else
    error_msg "Zsh yüklənmədi"
fi

# 11. Əlavə faydalı proqramlar
info_msg "Əlavə faydalı proqramlar yüklənir..."

# RPM Fusion (vlc, rar/unrar kimi paketlər üçün)
FEDORA_VER=$(rpm -E %fedora 2>/dev/null || echo "")
if [ -n "$FEDORA_VER" ]; then
    if confirm "Yüklə: RPM Fusion repoları?"; then
        sudo dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" \
            >/dev/null 2>&1 || warning_msg "RPM Fusion repoları əlavə edilmədi"
    else
        warning_msg "Keçildi: RPM Fusion"
    fi
fi

if confirm "Mərhələ: Əlavə faydalı proqramları yüklə? (htop, tree, vlc, gimp, ...)"; then
    sudo dnf install -y \
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
        vlc \
        gimp \
        firefox \
        thunderbird \
        || warning_msg "Bəzi əlavə paketlər yüklənmədi (ad/repoya görə dəyişə bilər)."
else
    warning_msg "Keçildi: Əlavə faydalı proqramlar"
fi

# rar/unrar paketləri hər sistemdə olmaya bilər
if confirm "Mərhələ: rar/unrar yüklə?"; then
    sudo dnf install -y rar unrar >/dev/null 2>&1 || warning_msg "rar/unrar yüklənmədi (RPM Fusion tələb oluna bilər)."
else
    warning_msg "Keçildi: rar/unrar"
fi

success_msg "Əlavə proqramlar quraşdırma addımı tamamlandı"

# 12. Sistem təmizliyi
info_msg "Sistem təmizlənir..."
if confirm "Mərhələ: Sistem təmizliyi? (autoremove + clean)"; then
    sudo dnf autoremove -y >/dev/null 2>&1 || true
    sudo dnf clean all >/dev/null 2>&1 || true
    success_msg "Sistem təmizləndi"
else
    warning_msg "Keçildi: Sistem təmizliyi"
fi

echo ""
echo "========================================"
echo -e "${GREEN}🎉 Fedora setup tamamlandı!${NC}"
echo ""
warning_msg "Qeyd: Docker-i sudo olmadan işlətmək üçün sistemdən çıxıb yenidən daxil olun və ya aşağıdakı əmri yerinə yetirin:"
echo -e "${YELLOW}newgrp docker${NC}"
echo ""
warning_msg "Zsh-i default shell olaraq istifadə etmək üçün sistemdən çıxıb yenidən daxil olun və ya yeni terminal açın."
echo ""
info_msg "Seçilən/yüklənə bilən proqramlar:"
echo "✅ Docker & Docker Compose"
echo "✅ Google Chrome"
echo "✅ Brave Browser"
echo "✅ Visual Studio Code"
echo "✅ Discord (Flatpak)"
echo "✅ Postman (Flatpak)"
echo "✅ Telegram Desktop (Flatpak)"
echo "✅ Zoom (Flatpak)"
echo "✅ OBS Studio (Flatpak)"
echo "✅ Steam (Flatpak)"
echo "✅ Notion (Flatpak - varsa)"
echo "✅ Slack (Flatpak)"
echo "✅ DBeaver (Flatpak)"
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
