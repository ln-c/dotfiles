<div align="center">
  <!-- Replace with your own banner or a beautiful screenshot snippet -->
  <img src="banner.png" width="800" alt="Dotfiles Banner" />
  
  # ❄️ Minimal Hyprland Dotfiles
  
  *Aesthetic, blazing-fast, and minimal configuration for Wayland.*
  
  ![OS](https://img.shields.io/badge/OS-Arch%20Linux-33a5da?style=for-the-badge&logo=arch-linux&logoColor=white)
  ![WM](https://img.shields.io/badge/WM-Hyprland-00a8f3?style=for-the-badge&logo=linux&logoColor=white)
  ![Terminal](https://img.shields.io/badge/Terminal-Foot-green?style=for-the-badge&logo=linux&logoColor=white)
  ![Theming](https://img.shields.io/badge/Theming-Wallust-f05032?style=for-the-badge&logo=linux&logoColor=white)
  
</div>

## 📖 Introduction

Welcome to my personal dotfiles. This repository contains the configuration files for my daily driver setup, built around **Hyprland** on Wayland. 

The core philosophy here is **uncompromising minimalism and performance combined with eye-candy dynamic theming**. By utilizing tools like Foot in server mode, native Waybar modules, and Wallust for blazing-fast dynamic colors, the setup is designed to get out of your way and let you focus, while keeping a unified, beautiful aesthetic.

## 🖼️ Showcase

<details>
<summary><b>Click to expand screenshots</b></summary>

| Clean Desktop | Busy Workspace |
| :---: | :---: |
| <img src="https://via.placeholder.com/400x225/1e1e2e/cba6f7?text=Clean+Desktop" alt="Clean Desktop"/> | <img src="https://via.placeholder.com/400x225/1e1e2e/cba6f7?text=Busy+Workspace" alt="Busy Workspace"/> |

| Terminal (Foot) | File Manager (Yazi) |
| :---: | :---: |
| <img src="https://via.placeholder.com/400x225/1e1e2e/cba6f7?text=Foot+Terminal" alt="Foot Terminal"/> | <img src="https://via.placeholder.com/400x225/1e1e2e/cba6f7?text=Yazi" alt="Yazi"/> |

</details>

## ⚙️ System Specifications / Verdicts

| Component | Choice | Verdict / Notes |
| --- | --- | --- |
| **OS** | [Arch Linux](https://archlinux.org/) | Rolling release, DIY approach. |
| **WM** | [Hyprland](https://hyprland.org/) | Snappy custom bezier curves and VFR enabled for battery life. |
| **Terminal** | [Foot](https://codeberg.org/dnkl/foot) | Runs in `--server` mode for minimal memory footprint. |
| **Shell** | [Starship](https://starship.rs/) | Minimal preset with strict 500ms command timeouts. |
| **Theming** | [Wallust](https://codeberg.org/explosion-mental/wallust) | Replaced Pywal; dynamic colors deployed via `ln-themectl`. |
| **Bar** | [Waybar](https://github.com/Alexays/Waybar) | Purely native modules (no heavy custom shell scripts). |
| **Launcher** | [Fuzzel](https://codeberg.org/dnkl/fuzzel) | Wayland-native, extremely fast application launcher. |
| **Files** | [Yazi](https://github.com/sxyazi/yazi) | Terminal file manager with `sixel` image previews in Foot. |

## 🛠️ Installation & Guidelines

> [!WARNING]
> **Do not install these dotfiles blindly on your main machine.** Configurations are highly personalized and running automated install scripts on a live host can cause unexpected behavior.

### Live Deployment

If you are absolutely ready to apply these configurations to your live host, we use a custom installation script rather than symlink managers like GNU Stow.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/git/dotfiles
   cd ~/git/dotfiles
   ```

2. **Execute the installation script:**
   *Note: Ensure you read through the script first to understand what files it will touch.*
   ```bash
   ./install.sh
   ```

## 📜 License

These dotfiles are licensed under the [GNU General Public License v3.0](LICENSE). Feel free to use, modify, and distribute them as you see fit to build your perfect workspace.

<div align="center">
  <i>If you found this repository helpful, consider leaving a ⭐!</i>
</div>
