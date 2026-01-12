#!/bin/bash
set -e
pacman -Syu --noconfirm

# --- 1. BASE SYSTEM & DRIVERS ---
# Get the hardware ready before the heavy apps
pacman -S --noconfirm --needed \
	mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
	libva-mesa-driver lib32-libva-mesa-driver \
	networkmanager bluez bluez-utils glib2 fontconfig \
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

# --- 4. TEMPORARY GHOST ---
echo "nobody ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nobody-build

# --- 5. AUR (Paru & Themes) ---
mkdir -p /tmp/paru
chmod 777 /tmp/paru
chown -R nobody:nobody /tmp/paru
su -s /bin/bash nobody -c "cd /tmp/paru && git clone https://aur.archlinux.org/paru-bin.git . && makepkg -si --noconfirm"
su -s /bin/bash nobody -c "paru -S --noconfirm --skipreview --needed --cachedir /tmp/paru_cache \
    bibata-cursor-theme-bin python-pywal hyprpanel-git hyprlauncher-git tty-clock hyprshot jetbrains-toolbox"
	
# --- 6. INSTALL CHOSEN APPS ---
mkdir -p /opt
[[ "$I_STEAM" == "y" ]] && pacman -S --noconfirm --needed steam
[[ "$I_BLENDER" == "y" ]] && pacman -S --noconfirm --needed blender
[[ "$I_OBS" == "y" ]] && pacman -S --noconfirm --needed obs-studio
[[ "$I_UNITY" == "y" ]] && mkdir -p /tmp/unity_home && chown nobody:nobody /tmp/unity_home && HOME=/tmp/unity_home su -s /bin/bash nobody -c "ACCEPT_EULA=Y paru -S --noconfirm --skipreview --needed --cachedir /tmp/paru_cache unityhub"
[[ "$I_REAPER" == "y" ]] && su -s /bin/bash nobody -c "paru -S --noconfirm --skipreview --needed --cachedir /tmp/paru_cache reaper-bin"

# --- 7. CLEANUP ---
rm /etc/sudoers.d/nobody-build
rm -rf /tmp/paru /tmp/paru_cache /tmp/unity_home
