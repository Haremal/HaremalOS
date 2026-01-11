#!/bin/bash
set -e

# --- 1. IDENTITY ---
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "haremalos" > /etc/hostname

cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   haremalos.localdomain haremalos
HOSTS

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd
chmod 440 /etc/sudoers.d/wheel-nopasswd

# --- 2. POLKIT ---
cat <<POLKIT > /etc/polkit-1/rules.d/49-nopasswd.rules
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
POLKIT

# --- 3. SKEL (The Blueprint for every new user) ---
mkdir -p /etc/skel/Media/{Documents,Pictures,Videos,Music,Downloads} 
mkdir -p /etc/skel/Settings/{Config,Data} /etc/skel/Projects

cat <<PROFILE > /etc/skel/.profile
# --- PATH & XDG ---
export XDG_CONFIG_HOME="\$HOME/Settings/Config"
export XDG_DATA_HOME="\$HOME/Settings/Data"
export XDG_DOCUMENTS_DIR="\$HOME/Media/Documents"
export XDG_PICTURES_DIR="\$HOME/Media/Pictures"
export XDG_VIDEOS_DIR="\$HOME/Media/Videos"
export XDG_MUSIC_DIR="\$HOME/Media/Music"
export XDG_DOWNLOAD_DIR="\$HOME/Media/Downloads"

# --- WAYLAND & DESKTOP ---
export XDG_CURRENT_DESKTOP="Hyprland"
export XDG_SESSION_TYPE="wayland"
export XDG_SESSION_DESKTOP="Hyprland"
export MOZ_ENABLE_WAYLAND="1"
export SDL_VIDEODRIVER="wayland"
export CLUTTER_BACKEND="wayland"
export GDK_BACKEND="wayland,x11"
export GDK_SCALE="1"

# --- TOOLKITS (Qt & Graphics) ---
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME="qt6ct"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export QT_AUTO_SCREEN_SCALE_FACTOR="1"
export LIBVA_DRIVER_NAME="radeonsi"
export XCURSOR_SIZE="24"
PROFILE

mkdir -p /etc/skel/Settings/Config/hypr
cat <<HYPR > /etc/skel/Settings/Config/hypr/hyprland.conf
bind = SUPER+R, exec, hyprlauncher
bind = SUPER+SPACE, exec, wezterm
bind = PRINT, exec, hyprshot -m region
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle
exec-once = hyprpaper
exec-once = hyprpanel
HYPR

mkdir -p /etc/skel/Settings/Config/yazi
cat <<YAZI > /etc/skel/Settings/Config/yazi/yazi.toml
[manager]
ratio          = [ 1, 3, 4 ] # Ranger-style columns
show_hidden    = true
sort_by        = "natural"
[preview]
max_width      = 1280
max_height     = 720
image_delay    = 30 # Smoother performance in WezTerm
[opener]
play    = { run = 'mpv "$@"', orphan = true, desc = "Play Video" }
copy    = { run = 'echo "$@" | wl-copy', desc = "Copy Path" }
extract = { run = '7z x "$@"', desc = "Extract Archive" }
[open]
rules = [
    { mime = "video/*", use = "play" },
    { mime = "audio/*", use = "play" },
    { name = "*.zip",   use = "extract" },
    { name = "*.7z",    use = "extract" }
]
YAZI
cat <<YAZIKEY > /etc/skel/Settings/Config/yazi/keymap.toml
[[manager.prepend_keymap]]
on   = [ "y" ]
run  = [ "copy path", "shell 'echo \"$@\" | wl-copy' --confirm" ]
desc = "Copy path to system clipboard"
YAZIKEY

mkdir -p /etc/skel/Settings/Config/xdg-desktop-portal
cat <<PORTALS > /etc/skel/Settings/Config/xdg-desktop-portal/portals.conf
[preferred]
default=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
PORTALS

# --- 4. THEME, CURSOR & FONT SETUP ---
mkdir -p /usr/share/glib-2.0/schemas/
cat <<CRS > /usr/share/glib-2.0/schemas/99_haremalos_defaults.gschema.override
[org.gnome.desktop.interface]
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Classic'
cursor-size=24
CRS
glib-compile-schemas /usr/share/glib-2.0/schemas/

mkdir -p /usr/share/fonts/TTF
curl -L -o /usr/share/fonts/TTF/Monocraft.ttc https://github.com/IdreesInc/Monocraft/releases/latest/download/Monocraft.ttc
fc-cache -fv

# --- 5. SESSION SETUP ---
mkdir -p /etc/ly
cat <<INI > /etc/ly/config.ini
[server]
session = hyprland
INI

# --- 6. SYSTEM ENABLE ---
systemctl disable getty@tty2.service
systemctl enable ly@tty2.service
systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable fstrim.timer
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true
yes | sensors-detect --auto > /dev/null || true
