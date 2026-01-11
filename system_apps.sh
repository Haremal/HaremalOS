#!/bin/bash
set -e
pacman -Syu --noconfirm

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	libva-mesa-driver lib32-libva-mesa-driver \
	networkmanager bluez bluez-utils \
	xdg-desktop-portal xdg-desktop-portal-hyprland gnome-keyring \
	xdg-desktop-portal-gtk xdg-utils hyprland-qt-support \
	wayland wayland-protocols xorg-server-xwayland python \
	polkit polkit-kde-agent gsettings-desktop-schemas \
	qt5-wayland qt6-wayland
	
# --- 2. THE HAERMALOS STACK (Core Apps) ---
pacman -S --noconfirm --needed \
	hyprland hyprpaper hypridle hyprlock mpv \
	ly pipewire pipewire-pulse wireplumber \
	wezterm neovim yazi fastfetch cava cmatrix \
	ffmpeg fd ripgrep p7zip unzip zip libnotify wl-clipboard \
	grim slurp playerctl lm_sensors papirus-icon-theme

# --- 3. LANGUAGES & DEV TOOLS ---
pacman -S --noconfirm --needed \
	base-devel git cmake ninja sdbus-cpp rust \
    dotnet-sdk jdk-openjdk lua-language-server


# TODO: THE WHOLE THING FROM HERE DOESNT WORK 
# --- 4. TEMPORARY USER CREATION ---
useradd -m -G wheel -s /bin/bash builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

# --- 5. AUR (Paru & Themes) ---
# We build the theme components as the temp user
su - builder -c "git clone https://aur.archlinux.org/paru-bin.git ~/paru && cd ~/paru && makepkg -si --noconfirm"
su - builder -c "paru -S --noconfirm --skipreview --needed bibata-cursor-theme-bin python-pywal hyprpanel-git hyprlauncher-git tty-clock hyprshot jetbrains-toolbox"

# --- 6. INSTALL CHOSEN APPS ---
mkdir -p /opt
[[ "$I_STEAM" == "y" ]] && pacman -S --noconfirm --needed steam
[[ "$I_BLENDER" == "y" ]] && pacman -S --noconfirm --needed blender
[[ "$I_OBS" == "y" ]] && pacman -S --noconfirm --needed obs-studio
[[ "$I_UNITY" == "y" ]] && su - builder -c "ACCEPT_EULA=Y paru -S --noconfirm --skipreview --needed unityhub"
[[ "$I_REAPER" == "y" ]] && su - builder -c "paru -S --noconfirm --skipreview --needed reaper-bin"

# --- 7. CLEANUP ---
pkill -9 -u builder || true
userdel -rf builder || true
rm -f /etc/sudoers.d/builder
