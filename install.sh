#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${DOTFILES_DIR}/install.log"
BACKUP_DIR="${HOME}/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
HAS_BACKUP=false

# ANSI colors
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_GREEN="\033[32m"
CLR_YELLOW="\033[33m"
CLR_RED="\033[31m"
CLR_CYAN="\033[36m"

log_info()    { echo -e "${CLR_CYAN}[INFO]${CLR_RESET} $*"; }
log_step()    { echo -e "\n${CLR_BOLD}${CLR_CYAN}==>${CLR_RESET} ${CLR_BOLD}$*${CLR_RESET}"; }
log_success() { echo -e "${CLR_GREEN}[OK]${CLR_RESET}   $*"; }
log_warn()    { echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $*"; }
log_error()   { echo -e "${CLR_RED}[ERROR]${CLR_RESET} $*" >&2; }

trap 'log_error "Script failed at line $LINENO. See $LOG_FILE for full logs."; exit 1' ERR

# Log output
exec > >(tee -a "$LOG_FILE") 2>&1

# 0. Pre-flight checks
log_step "Running pre-flight checks..."
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run this script as root/sudo! It needs to install files into \$HOME."
    exit 1
fi

if [ ! -f /etc/arch-release ]; then
    log_warn "This system does not appear to be Arch Linux. Dependencies might fail."
fi

# Keep sudo timestamp updated
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 1. Dependency definitions
CORE_PKGS=(
    hyprland waybar foot fuzzel
    git rsync python
    starship yazi ttf-nerd-fonts-symbols
    fastfetch wl-clipboard ffmpeg mpv imagemagick mako libnotify
)
AUR_PKGS=(
    python-pywal
)

# 2. AUR helper detection & bootstrap
log_step "Checking package managers..."
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
else
    log_warn "Neither paru nor yay was found."
    read -rp "Install yay-bin automatically? [Y/n] " ans
    ans=${ans:-Y}
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        log_info "Installing yay-bin..."
        sudo pacman -S --needed --noconfirm base-devel git
        TMP_YAY=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY"
        (cd "$TMP_YAY" && makepkg -si --noconfirm)
        rm -rf "$TMP_YAY"
        AUR_HELPER="yay"
    else
        log_warn "Skipping AUR helper installation. AUR packages will need manual installation."
    fi
fi

# 3. Package installation
log_step "Installing dependencies..."
sudo pacman -S --needed --noconfirm "${CORE_PKGS[@]}"

if [ -n "$AUR_HELPER" ]; then
    log_info "Installing AUR packages using $AUR_HELPER..."
    "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    log_warn "Please install ${AUR_PKGS[*]} manually."
fi

# 4. Safe deployment & backup function
backup_and_copy() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$HAS_BACKUP" = false ]; then
            mkdir -p "$BACKUP_DIR"
            HAS_BACKUP=true
            log_info "Backup directory created at $BACKUP_DIR"
        fi

        log_warn "Backing up existing $dest to $BACKUP_DIR/"
        mv "$dest" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    log_success "Copied $dest <- $src"
}

# 5. Deploy configurations
log_step "Deploying configurations..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

if [ -d "$DOTFILES_DIR/.config" ]; then
    for item in "$DOTFILES_DIR/.config"/*; do
        [ -e "$item" ] || continue
        base=$(basename "$item")
        backup_and_copy "$item" "$HOME/.config/$base"
    done
fi

if [ -d "$DOTFILES_DIR/.local/bin" ]; then
    for script in "$DOTFILES_DIR/.local/bin"/*; do
        [ -e "$script" ] || continue
        base=$(basename "$script")
        backup_and_copy "$script" "$HOME/.local/bin/$base"
        chmod +x "$HOME/.local/bin/$base"
    done
fi

# 6. Post-install
log_step "Updating font cache..."
fc-cache -f >/dev/null 2>&1 || true

log_step "Installation complete!"
if [ "$HAS_BACKUP" = true ]; then
    log_info "Backups saved to: $BACKUP_DIR"
fi
log_info "Installation log written to: $LOG_FILE"
log_info "You may want to log out and log back into Hyprland to load your new environment."
