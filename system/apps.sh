#!/bin/bash
set -exuo pipefail
pacman -Syu --noconfirm

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	libva-mesa-driver lib32-libva-mesa-driver libva-utils \
	pipewire pipewire-pulse pipewire-alsa pipewire-jack \
	networkmanager bluez bluez-utils glib2 fontconfig \
	xdg-desktop-portal xdg-desktop-portal-gnome \
	wayland wayland-protocols xorg-server-xwayland \
	polkit hyprpolkitagent gsettings-desktop-schemas \
	libsecret gnome-keyring xdg-utils qt5-wayland qt6-wayland

# --- 2. RUST ---
pacman -S --noconfirm --needed \
	base-devel git socat ninja jq \
	rust rust-analyzer clang mold

export CARGO_HOME="/opt/cargo"
export PATH="$CARGO_HOME/bin:$PATH"
cargo install dioxus-cli cargo-watch cargo-bundle

# --- 3. THE HAREMAL OS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	lemurs niri swww eww-git wallust-git hypridle hyprlock \
	rio helix zellij yazi imagemagick fastfetch cava neo-matrix-git \
	mpv ffmpeg ouch grim slurp wl-clipboard-rs libnotify wireplumber \
	brightnessctl lm_sensors fd ripgrep papirus-icon-theme bibata-cursor-theme 

# --- 4. CHOSEN APPS ---
[[ "${I_STEAM:-N}" =~ [Yy] ]] && pacman -S --noconfirm --needed steam
[[ "${I_BLENDER:-N}" =~ [Yy] ]] && pacman -S --noconfirm --needed blender
[[ "${I_FYROX:-N}" =~ [Yy] ]] && cargo install fyrox-project-manager
[[ "${I_OBS:-N}" =~ [Yy] ]] && pacman -S --noconfirm --needed obs-studio
[[ "${I_ARDOUR:-N}" =~ [Yy] ]] && pacman -S --noconfirm --needed ardour
[[ "${I_BITWARDEN:-N}" =~ [Yy] ]] && pacman -S --noconfirm --needed bitwarden bitwarden-cli
