#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="$DIR/../vm_data"

if ! command -v cloud-localds &> /dev/null; then
    echo "Error: cloud-localds is required to build the cloud-init seed ISO."
    echo "Please install it: sudo pacman -S cloud-guest-utils"
    exit 1
fi

mkdir -p "$VM_DIR"
cd "$VM_DIR"

if [ ! -f arch-base.qcow2 ]; then
    echo "Downloading Arch Linux cloud image..."
    wget -O arch-base.qcow2 "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
fi

if [ ! -f id_ed25519 ]; then
    ssh-keygen -t ed25519 -f id_ed25519 -N "" -q
fi
SSH_PUB_KEY=$(cat id_ed25519.pub)

cat <<YAMLEOF > user-data
#cloud-config
users:
  - name: ln
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel, video, input, audio, seat
    ssh_authorized_keys:
      - $SSH_PUB_KEY
    shell: /bin/bash
YAMLEOF

cat <<YAMLEOF > meta-data
instance-id: arch-vm
local-hostname: arch-vm
YAMLEOF

cloud-localds seed.iso user-data meta-data

cp arch-base.qcow2 disk.qcow2
qemu-img resize disk.qcow2 +10G
echo "Setup complete. VM image ready at $VM_DIR/disk.qcow2"
