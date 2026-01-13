#!/bin/bash
set -exuo pipefail
pacman -Syu --noconfirm

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	libva-mesa-driver lib32-libva-mesa-driver wev \
	networkmanager bluez bluez-utils glib2 fontconfig \
	xdg-desktop-portal xdg-desktop-portal-hyprland gnome-keyring \
	xdg-desktop-portal-gtk xdg-utils hyprland-qt-support \
	wayland wayland-protocols xorg-server-xwayland python \
	polkit polkit-kde-agent gsettings-desktop-schemas \
	qt5-wayland qt6-wayland
	
# --- 2. THE HAERMALOS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	hyprland ags-hyprpanel-git hyprpaper hypridle hyprlock hyprlauncher hyprshot \
	ly paru pipewire pipewire-pulse wireplumber mpvpaper mpv grim slurp \
	wezterm neovim yazi fastfetch cava cmatrix tty-clock \
	ffmpeg fd ripgrep p7zip unzip zip libnotify wl-clipboard \
	playerctl lm_sensors papirus-icon-theme python-pywal bibata-cursor-theme
	
# --- 3. LANGUAGES & DEV TOOLS ---
pacman -S --noconfirm --needed \
	base-devel git cmake ninja sdbus-cpp rust \
    dotnet-sdk jdk-openjdk lua-language-server

# --- 4. CHOSEN APPS ---
[[ "${I_STEAM}" =~ [Yy] ]] && pacman -S --noconfirm --needed steam
[[ "${I_TOOLBOX}" =~ [Yy] ]] && pacman -S --noconfirm --needed jetbrains-toolbox
[[ "${I_BLENDER}" =~ [Yy] ]] && pacman -S --noconfirm --needed blender
[[ "$I_UNITY" =~ [Yy] ]] && pacman -S --noconfirm --needed unityhub
[[ "${I_OBS}" =~ [Yy] ]] && pacman -S --noconfirm --needed obs-studio
[[ "${I_ARDOUR}" =~ [Yy] ]] && pacman -S --noconfirm --needed ardour
