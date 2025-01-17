#!/bin/bash

# Enable error handling
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logger function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
}

# Function to install yay AUR helper
install_yay() {
    log "Installing yay AUR helper..."
    if ! command -v yay &> /dev/null; then
        pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    else
        log "yay is already installed"
    fi
}

# Essential system packages
install_system_essentials() {
    log "Installing system essentials..."
    pacman -S --needed --noconfirm \
        base-devel \
        linux-headers \
        networkmanager \
        network-manager-applet \
        wireless_tools \
        wpa_supplicant \
        dialog \
        os-prober \
        mtools \
        dosfstools \
        reflector \
        cups \
        htop \
        acpi \
        acpi_call \
        tlp \
        git \
        wget \
        unzip \
        zip \
        p7zip \
        alsa-utils \
        sof-firmware \
        pulseaudio \
        pulseaudio-alsa \
        pavucontrol
}

# Development tools
install_dev_tools() {
    log "Installing development tools..."
    pacman -S --needed --noconfirm \
        vim \
        neovim \
        python \
        python-pip \
        nodejs \
        npm \
        docker \
        docker-compose \
        visual-studio-code-bin \
        git-lfs \
        tmux \
        zsh \
        rust \
        go \
        jdk-openjdk \
        maven \
        gradle
}

# Install desktop environment (GNOME as example)
install_desktop_env() {
    log "Installing desktop environment..."
    pacman -S --needed --noconfirm \
        xorg \
        xorg-server \
        gnome \
        gnome-tweaks \
        gnome-shell-extensions
        
    # Enable GDM
    systemctl enable gdm
}

# Install browsers and communication tools
install_daily_apps() {
    log "Installing daily use applications..."
    pacman -S --needed --noconfirm \
        firefox \
        chromium \
        telegram-desktop \
        discord \
        obsidian \
        flameshot \
        vlc
}

# Install AUR packages
install_aur_packages() {
    log "Installing AUR packages..."
    yay -S --needed --noconfirm \
        visual-studio-code-bin \
        spotify \
        zoom \
        google-chrome
}

# Enable essential services
enable_services() {
    log "Enabling essential services..."
    systemctl enable NetworkManager
    systemctl enable cups.service
    systemctl enable tlp.service
    systemctl enable docker.service
}

# Configure git
configure_git() {
    log "Configuring git..."
    read -p "Enter your git username: " git_username
    read -p "Enter your git email: " git_email
    
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "nvim"
}

# Setup ZSH
setup_zsh() {
    log "Setting up ZSH..."
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    
    # Backup existing .zshrc if it exists
    [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
    
    # Create new .zshrc with custom configuration
    cat > ~/.zshrc << 'EOL'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
    git
    docker
    docker-compose
    node
    npm
    python
    pip
    zsh-autosuggestions
    zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh
EOL
}

# Main installation process
main() {
    check_root
    log "Starting Arch Linux setup..."
    
    # Update system first
    log "Updating system..."
    pacman -Syu --noconfirm
    
    install_yay
    install_system_essentials
    install_dev_tools
    install_desktop_env
    install_daily_apps
    install_aur_packages
    enable_services
    
    # User specific configurations
    # Run these as normal user
    su - $SUDO_USER << 'EOF'
    configure_git
    setup_zsh
EOF
    
    log "Installation completed! Please reboot your system."
}

# Run the script
main "$@"