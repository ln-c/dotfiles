#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing required dependencies..."
if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm \
        hyprland waybar foot fuzzel \
        git rsync python python-pywal \
        starship yazi ttf-nerd-fonts-symbols \
        fastfetch wl-clipboard ffmpeg mpv imagemagick mako libnotify
else
    echo "paru not found. Installing standard packages with pacman..."
    sudo pacman -S --needed --noconfirm \
        hyprland waybar foot fuzzel \
        git rsync python \
        starship yazi ttf-nerd-fonts-symbols \
        fastfetch wl-clipboard ffmpeg mpv imagemagick mako libnotify
    echo "Please install python-pywal manually from the AUR."
fi

echo "Creating necessary directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin

echo "Deploying configurations via hard copy..."
for item in "$DOTFILES_DIR/.config"/*; do
    basename=$(basename "$item")
    echo "Copying ~/.config/$basename"
    
    if [ -e "$HOME/.config/$basename" ]; then
        rm -rf "$HOME/.config/$basename"
    fi
    
    cp -r "$item" "$HOME/.config/$basename"
done

echo "Deploying local scripts via hard copy..."
for script in "$DOTFILES_DIR/.local/bin"/*; do
    basename=$(basename "$script")
    echo "Copying ~/.local/bin/$basename"
    
    if [ -e "$HOME/.local/bin/$basename" ]; then
        rm -rf "$HOME/.local/bin/$basename"
    fi
    
    cp -r "$script" "$HOME/.local/bin/$basename"
    chmod +x "$HOME/.local/bin/$basename"
done

echo "Installation complete!"
