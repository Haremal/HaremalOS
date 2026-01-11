# HaremalOS
> A minimalist, performance-driven Arch Linux distribution optimized for AMD hardware and the Wayland compositor.

---

## 🚀 Overview
**HaremalOS** is designed for users who want the power of Arch Linux without the manual friction of setting up a modern Wayland environment. It features a curated selection of tools focused on efficiency, aesthetics, and hardware synergy.

## ✨ Key Features
* **Compositor:** [Hyprland](https://hyprland.org/) (Dynamic Tiling Wayland Compositor)
* **Performance:** Hard-coded optimizations for **AMD CPUs** and **AMD GPUs** (Mesa/Vulkan).
* **Workflow:** Terminal-centric with `Yazi`, `WezTerm`, and `Neovim`.
* **Display Manager:** `Ly` TUI (on TTY2) for a lightweight login experience.
* **Organization:** Strict adherence to XDG path standards (Media/Settings separation).

## 🛠 Tech Stack
| Component | Choice |
| :--- | :--- |
| **Base** | Arch Linux |
| **Shell** | Bash / Zsh |
| **Terminal** | WezTerm |
| **AUR Helper** | Paru (Rust-based) |
| **Audio** | Pipewire / Wireplumber |

## 📥 Installation
1.  **Boot** the official HaremalOS Live ISO.
2.  **Connect** to the internet.
3.  **Run** the installer (if it doesn't auto-start):
```bash
bash <(curl -sL [https://raw.githubusercontent.com/youruser/HaremalOS/main/install.sh](https://raw.githubusercontent.com/youruser/HaremalOS/main/install.sh))
