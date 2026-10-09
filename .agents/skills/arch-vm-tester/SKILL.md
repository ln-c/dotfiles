---
name: arch-vm-tester
description: >-
  Provides tools and scripts to test Hyprland dotfiles inside an Arch Linux Virtual Machine.
  Activate this skill when the user asks you to "test my changes", "verify the dotfiles",
  or "spin up the testing VM".
---

# Arch Linux VM Testing Skill

This repository manages dotfiles for a Wayland/Hyprland environment. Testing these changes directly on the host is forbidden. Instead, we use an automated QEMU/KVM Virtual Machine that mirrors the host's setup and mounts the repository directly into the VM.

## Usage Instructions for the Agent

When tasked with testing dotfile changes, follow these steps autonomously:

### 1. Ensure Prerequisites
Check if the VM dependencies are available on the host (like `qemu-system-x86_64` and `cloud-localds`). If `cloud-localds` is missing, inform the user to install `cloud-guest-utils` on their host machine.

### 2. Setup the VM (One-time)
If the VM image doesn't exist yet at `.agents/skills/arch-vm-tester/vm_data/disk.qcow2`, run the setup script:
```bash
./.agents/skills/arch-vm-tester/scripts/setup.sh
```

### 3. Start the VM
Run the VM launcher script in the background:
```bash
./.agents/skills/arch-vm-tester/scripts/run.sh
```
Wait a minute for the VM to boot up. The script automatically exposes SSH on port `2222`.

### 4. Provision and Test
Once the VM is running, you can connect to it via SSH to run commands, apply the dotfiles, or trigger tests. Use the provided SSH key in the `vm_data` folder:
```bash
# Example SSH command:
ssh -o StrictHostKeyChecking=no -i .agents/skills/arch-vm-tester/vm_data/id_ed25519 -p 2222 ln@localhost "bash -s" < .agents/skills/arch-vm-tester/scripts/provision-guest.sh
```

### 5. Validate the Configuration
To verify that the configuration files are valid, you can run commands inside the VM. For example, testing if Hyprland can parse its config without crashing:
```bash
ssh -i .agents/skills/arch-vm-tester/vm_data/id_ed25519 -p 2222 ln@localhost "hyprctl help || echo 'Hyprland config might be broken'"
```
(Note: Since Hyprland requires an active session, simple syntax checks or checking waybar configs via `waybar -c ~/.config/waybar/config` might be easier).

## Architecture
- **Hypervisor:** QEMU/KVM
- **Graphics:** `virtio-gpu` with VirGL 3D Acceleration (Required for Wayland/Hyprland)
- **Syncing:** `virtfs` (9P) mounts the host's `~/git/dotfiles` directly to `~/git/dotfiles` inside the VM.

