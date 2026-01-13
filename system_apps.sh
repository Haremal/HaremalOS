#!/bin/bash
set -exuo pipefail
pacman -Syu --noconfirm

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	libva-mesa-driver lib32-libva-mesa-driver libva-utils \
	pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
	networkmanager bluez bluez-utils glib2 fontconfig \
	xdg-desktop-portal xdg-desktop-portal-hyprland gnome-keyring \
	xdg-desktop-portal-gtk xdg-utils hyprland-qt-support \
	wayland wayland-protocols xorg-server-xwayland python \
	polkit polkit-kde-agent gsettings-desktop-schemas \
	qt5-wayland qt6-wayland base-devel gcc cmake socat git
	
# --- 2. THE HAERMALOS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	ly hyprland swww hypridle hyprlock hyprcursor \
	foot chafa neovim yazi fastfetch cava cmatrix tty-clock \
	ffmpeg fd ripgrep p7zip unzip zip libnotify grim slurp wl-clipboard mpv \
	eww-wayland-git brightnessctl playerctl lm_sensors papirus-icon-theme bibata-cursor-theme python-pywal
	
# --- 3. LANGUAGES & DEV TOOLS ---
pacman -S --noconfirm --needed \
	ninja nlohmann-json sdbus-cpp rust jq \
    dotnet-sdk jdk-openjdk lua-language-server

# --- 4. CHOSEN APPS ---
[[ "${I_STEAM}" =~ [Yy] ]] && pacman -S --noconfirm --needed steam
[[ "${I_TOOLBOX}" =~ [Yy] ]] && pacman -S --noconfirm --needed jetbrains-toolbox
[[ "${I_BLENDER}" =~ [Yy] ]] && pacman -S --noconfirm --needed blender
[[ "$I_UNITY" =~ [Yy] ]] && pacman -S --noconfirm --needed unityhub
[[ "${I_OBS}" =~ [Yy] ]] && pacman -S --noconfirm --needed obs-studio
[[ "${I_ARDOUR}" =~ [Yy] ]] && pacman -S --noconfirm --needed ardour
