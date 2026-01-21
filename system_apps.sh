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
	polkit polkit-gnome gsettings-desktop-schemas \
	gnome-keyring xdg-utils qt5-wayland qt6-wayland

# --- 2. RUST ---
pacman -S --noconfirm --needed \
	base-devel git socat ninja jq zellij \
	rust rust-analyzer clippy clang mold
	
cargo install --root /usr/local dioxus-cli cargo-watch cargo-bundle

# --- 3. THE HAREMAL OS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	lemurs niri swww eww-git wallust-git hypridle hyprlock \
	rio helix yazi imagemagick fastfetch cava neo-matrix-git \
	mpv ffmpeg ouch grim slurp wl-clipboard-rs libnotify wireplumber \
	brightnessctl lm_sensors fd ripgrep papirus-icon-theme bibata-cursor-theme 

# --- 4. CHOSEN APPS ---
[[ "${I_STEAM}" =~ [Yy] ]] && pacman -S --noconfirm --needed steam
[[ "${I_BLENDER}" =~ [Yy] ]] && pacman -S --noconfirm --needed blender
# [[ "$I_UNITY" =~ [Yy] ]] && pacman -S --noconfirm --needed unityhub REPLACE WITH Bevy or Fyrox
[[ "${I_OBS}" =~ [Yy] ]] && pacman -S --noconfirm --needed obs-studio
[[ "${I_ARDOUR}" =~ [Yy] ]] && pacman -S --noconfirm --needed ardour
[[ "${I_BITWARDEN}" =~ [Yy] ]] && pacman -S --noconfirm --needed bitwarden bitwarden-cli
