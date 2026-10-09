#!/bin/bash
# This script is meant to be executed INSIDE the VM.
set -e

echo "Provisioning Arch VM for Hyprland testing..."

# Initialize pacman keys and update
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy --noconfirm archlinux-keyring
# (Omit full system upgrade for speed, we just need packages)

# Install base tools and hyprland requirements
sudo pacman -S --noconfirm \
    hyprland waybar foot fuzzel \
    git rsync python python-pip \
    starship yazi ttf-nerd-fonts-symbols \
    mesa vulkan-virtio fastfetch wl-clipboard ffmpeg mpv imagemagick mako libnotify

# Install pywal via pip in the VM (since paru isn't configured in the VM)
sudo pip install --break-system-packages pywal

# Setup 9p mount for dotfiles
mkdir -p ~/git/dotfiles
sudo mount -t 9p -o trans=virtio,version=9p2000.L host_dotfiles ~/git/dotfiles
echo "host_dotfiles /home/ln/git/dotfiles 9p trans=virtio,version=9p2000.L,rw 0 0" | sudo tee -a /etc/fstab

# Copy scripts and configs
echo "Applying dotfiles from host..."
# Using the install script if it exists, otherwise manual copy
if [ -f ~/git/dotfiles/install.sh ]; then
    cd ~/git/dotfiles && bash install.sh
else
    mkdir -p ~/.config ~/.local/bin
    cp -r ~/git/dotfiles/.config/* ~/.config/
    if [ -d ~/git/dotfiles/.local/bin ]; then
        cp -r ~/git/dotfiles/.local/bin/* ~/.local/bin/
    fi
fi

echo "Provisioning complete. You can now launch Hyprland!"
