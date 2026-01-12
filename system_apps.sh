#!/bin/bash
set -exuo pipefail
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




# --- 4. PERMISSIONS & TEMP BUILDER ---
pacman -Sy --noconfirm
useradd -m -G wheel builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

# --- 5. AUR APPS ---
sudo -u builder bash <<AUR_EOF
  cd /home/builder
  git clone https://aur.archlinux.org/paru-bin.git
  cd paru-bin && makepkg -si --noconfirm

  paru -S --noconfirm \
    bibata-cursor-theme-bin python-pywal hyprpanel-git \
    hyprlauncher-git tty-clock hyprshot jetbrains-toolbox

  [[ "$I_UNITY" =~ [Yy] ]] && paru -S --noconfirm unity-hub
AUR_EOF

# --- 6. INSTALL CHOSEN APPS ---
mkdir -p /opt
[[ "${I_STEAM}" =~ [Yy] ]]   && pacman -S --noconfirm --needed steam
[[ "${I_BLENDER}" =~ [Yy] ]] && pacman -S --noconfirm --needed blender
[[ "${I_OBS}" =~ [Yy] ]]     && pacman -S --noconfirm --needed obs-studio
[[ "${I_ARDOUR}" =~ [Yy] ]]     && pacman -S --noconfirm --needed ardour

# --- 7. CLEANUP ---
rm /etc/sudoers.d/builder
userdel -rf builder
