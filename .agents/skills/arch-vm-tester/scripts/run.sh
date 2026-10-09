#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="$DIR/../vm_data"
# The dotfiles repo root is three levels up from the scripts dir
DOTFILES_DIR="$(cd "$DIR/../../../.." && pwd)"

if [ ! -f "$VM_DIR/disk.qcow2" ]; then
    echo "Error: VM disk not found. Run setup.sh first."
    exit 1
fi

echo "Starting Arch VM in background..."
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 \
  -machine q35 -cpu host \
  -device virtio-vga-gl -display gtk,gl=on \
  -drive file="$VM_DIR/disk.qcow2",format=qcow2,if=virtio \
  -drive file="$VM_DIR/seed.iso",format=raw,if=virtio \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -virtfs local,path="$DOTFILES_DIR",mount_tag=host_dotfiles,security_model=none,id=dotfiles \
  -daemonize

echo "VM started successfully!"
echo "You can SSH into it with: ssh -i $VM_DIR/id_ed25519 -p 2222 ln@localhost"
