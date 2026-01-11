#!/bin/bash
set -e

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	grub efibootmgr networkmanager bluez bluez-utils \
	xdg-desktop-portal xdg-desktop-portal-hyprland \
	xdg-desktop-portal-gtk xdg-utils hyprland-qt-support \
	wayland wayland-protocols xorg-server-xwayland python \
	polkit polkit-kde-agent gsettings-desktop-schemas \
	
# --- 2. THE HAERMALOS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	hyprland hyprpaper hypridle hyprlock mpv \
	ly pipewire pipewire-pulse wireplumber \
	wezterm neovim yazi fastfetch cava cmatrix \
	ffmpeg fd ripgrep p7zip libnotify wl-clipboard \
	grim slurp playerctl lm_sensors papirus-icon-theme \

# --- 3. LANGUAGES & DEV TOOLS ---
pacman -S --noconfirm --needed \
	base-devel cmake ninja sdbus-cpp git rust \
    dotnet-sdk jdk-openjdk lua-language-server

# --- 4. TEMPORARY USER CREATION ---
useradd -m -G wheel -s /bin/bash haremalos
echo "haremalos:haremalos" | chpasswd

# --- 5. AUR (Paru & Themes) ---
# We build the theme components as the temp user
su - haremalos -c "git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si --noconfirm"
su - haremalos -c "paru -S --noconfirm --skipreview bibata-cursor-theme python-pywal hyprpanel-git hyprlauncher-git tty-clock hyprshot qt5-wayland qt6-wayland jetbrains-toolbox"

# --- 6. INSTALL CHOSEN APPS ---
mkdir -p /opt
[[ "$I_STEAM" == "y" ]] && pacman -S --noconfirm steam
[[ "$I_BLENDER" == "y" ]] && pacman -S --noconfirm blender
[[ "$I_OBS" == "y" ]] && pacman -S --noconfirm obs-studio
[[ "$I_UNITY" == "y" ]] && su - haremalos -c "paru -S --noconfirm --skipreview unityhub"
[[ "$I_REAPER" == "y" ]] && su - haremalos -c "paru -S --noconfirm --skipreview reaper-bin"

# --- 7. TEMPORARY USER DELETION ---
pkill -9 -u haremalos || true
userdel -r haremalos
