#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing required dependencies..."
# Use paru to install packages including AUR packages like python-pywal
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

echo "Deploying configurations..."
for item in "$DOTFILES_DIR/.config"/*; do
    basename=$(basename "$item")
    echo "Symlinking ~/.config/$basename"
    
    if [ -e "$HOME/.config/$basename" ] && [ ! -L "$HOME/.config/$basename" ]; then
        mv "$HOME/.config/$basename" "$HOME/.config/$basename.bak"
    fi
    
    ln -sfn "$item" "$HOME/.config/$basename"
done

echo "Deploying local scripts..."
for script in "$DOTFILES_DIR/.local/bin"/*; do
    basename=$(basename "$script")
    echo "Symlinking ~/.local/bin/$basename"
    
    if [ -e "$HOME/.local/bin/$basename" ] && [ ! -L "$HOME/.local/bin/$basename" ]; then
        mv "$HOME/.local/bin/$basename" "$HOME/.local/bin/$basename.bak"
    fi
    
    ln -sfn "$script" "$HOME/.local/bin/$basename"
    chmod +x "$HOME/.local/bin/$basename"
done

echo "Installation complete!"
