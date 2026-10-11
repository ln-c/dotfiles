#!/usr/bin/env bash
set -Eeuo pipefail

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

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
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done </dev/null >/dev/null 2>&1 &
SUDO_LOOP_PID=$!
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true; log_error "Script failed at line $LINENO. See $LOG_FILE for full logs."; exit 1' ERR

# 1. Dependency definitions
CORE_PKGS=(
    hyprland waybar foot fuzzel
    git rsync python
    starship yazi ttf-nerd-fonts-symbols
    fastfetch wl-clipboard ffmpeg mpv imagemagick mako libnotify
    hyprpaper hyprlock hypridle
)
AUR_PKGS=(
    wallust
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

# Filter AUR packages to only those whose binary is not already in PATH
NEEDED_AUR_PKGS=()
for pkg in "${AUR_PKGS[@]}"; do
    if command -v "$pkg" &>/dev/null; then
        log_info "Package binary '$pkg' is already available in PATH, skipping AUR installation."
    else
        NEEDED_AUR_PKGS+=("$pkg")
    fi
done

if [ ${#NEEDED_AUR_PKGS[@]} -gt 0 ]; then
    if [ -n "$AUR_HELPER" ]; then
        log_info "Installing needed AUR packages using $AUR_HELPER: ${NEEDED_AUR_PKGS[*]}..."
        for pkg in "${NEEDED_AUR_PKGS[@]}"; do
            if command -v "$pkg" &>/dev/null; then
                log_info "Package binary '$pkg' is already available in PATH, skipping."
                continue
            fi
            log_info "Attempting AUR install of $pkg..."
            aur_status=0
            "$AUR_HELPER" -S --needed --noconfirm "$pkg" || aur_status=$?
            if [ "$aur_status" -ne 0 ]; then
                log_warn "AUR installation of $pkg via $AUR_HELPER failed (exit code $aur_status)."
                if [ "$pkg" = "wallust" ]; then
                    if command -v wallust &>/dev/null; then
                        log_info "wallust binary is already present in PATH, continuing."
                    else
                        log_info "Attempting fallback installation of prebuilt wallust binary..."
                        TMP_DIR=$(mktemp -d)
                        if curl -sSL "https://codeberg.org/explosion-mental/wallust/releases/download/3.5.2/wallust-3.5.2-x86_64-unknown-linux-musl.tar.gz" -o "$TMP_DIR/wallust.tar.gz" 2>/dev/null && \
                           tar -xzf "$TMP_DIR/wallust.tar.gz" -C "$TMP_DIR" wallust 2>/dev/null && \
                           sudo install -m 755 "$TMP_DIR/wallust" /usr/local/bin/wallust; then
                            log_success "Successfully installed prebuilt wallust binary to /usr/local/bin/wallust."
                        else
                            log_warn "Could not install prebuilt wallust binary automatically."
                        fi
                        rm -rf "$TMP_DIR"
                    fi
                fi
            else
                log_success "Successfully installed $pkg via $AUR_HELPER."
            fi
        done
    else
        log_warn "No AUR helper found. Please install ${NEEDED_AUR_PKGS[*]} manually."
    fi
else
    log_success "All AUR package binaries are already present in PATH."
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

if [ -d "$DOTFILES_DIR/wallpapers" ]; then
    log_step "Deploying wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers/videos"
    for wp in "$DOTFILES_DIR/wallpapers"/*; do
        [ -e "$wp" ] || continue
        base=$(basename "$wp")
        backup_and_copy "$wp" "$HOME/Pictures/Wallpapers/$base"
        if [[ "$base" =~ \.(mp4|webm|mkv|gif|avi|mov)$ ]]; then
            backup_and_copy "$wp" "$HOME/Pictures/Wallpapers/videos/$base"
            thumb="${wp%.*}.jpg"
            if [ -f "$thumb" ]; then
                backup_and_copy "$thumb" "$HOME/Pictures/Wallpapers/videos/$(basename "$thumb")"
            fi
        fi
    done
fi

# 6. Post-install
# 5.5. Deploy root-level dotfiles
log_step "Deploying root-level dotfiles..."
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
    backup_and_copy "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
fi

log_step "Updating font cache..."
fc-cache -f >/dev/null 2>&1 || true

log_step "Initializing default theme..."
if [ -f "$HOME/.local/bin/ln-themectl" ]; then
    bash "$HOME/.local/bin/ln-themectl" >/dev/null 2>&1 || true
fi

log_step "Installation complete!"
if [ "$HAS_BACKUP" = true ]; then
    log_info "Backups saved to: $BACKUP_DIR"
fi
log_info "Installation log written to: $LOG_FILE"
log_info "You may want to log out and log back into Hyprland to load your new environment."

kill "$SUDO_LOOP_PID" 2>/dev/null || true
exec 1>&- 2>&-
