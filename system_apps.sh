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




# --- 4. PREP BUILD SPACE ---
mkdir -p /tmp/build_home
chown -R nobody:nobody /tmp/build_home
usermod -s /bin/bash nobody
echo "nobody ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nobody-build
sudo -u nobody HOME=/tmp/build_home bash <<EOF
  cd /tmp
  git clone https://aur.archlinux.org/paru-bin.git
  cd paru-bin
  makepkg -si --noconfirm
EOF

# --- 5. AUR APPS ---
sudo -u nobody HOME=/tmp/build_home paru -S --noconfirm --skipreview --needed \
    bibata-cursor-theme-bin python-pywal hyprpanel-git \
    hyprlauncher-git tty-clock hyprshot jetbrains-toolbox
	
# --- 6. INSTALL CHOSEN APPS ---
mkdir -p /opt

[[ "$I_STEAM" == "y" ]] && pacman -S --noconfirm --needed steam
[[ "$I_BLENDER" == "y" ]] && pacman -S --noconfirm --needed blender
[[ "$I_OBS" == "y" ]] && pacman -S --noconfirm --needed obs-studio

# Unity & Reaper (Fixed with sudo -u and HOME)
[[ "$I_UNITY" == "y" ]] && {
    mkdir -p /tmp/unity_home && chown nobody:nobody /tmp/unity_home
    sudo -u nobody HOME=/tmp/unity_home ACCEPT_EULA=Y paru -S --noconfirm --skipreview --needed unityhub
}
[[ "$I_REAPER" == "y" ]] && {
    sudo -u nobody HOME=/tmp/build_home paru -S --noconfirm --skipreview --needed reaper-bin
}

# --- 7. CLEANUP ---
rm /etc/sudoers.d/nobody-build
rm -rf /tmp/build_home /tmp/paru-bin	


# 8. The verification check
if pacman -Qi bibata-cursor-theme-bin > /dev/null; then
    echo "VERIFIED: AUR Apps installed successfully."
else
    echo "ERROR: AUR Apps missing. Check /tmp/build_home for logs."
    exit 1
fi
