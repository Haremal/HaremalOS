#!/bin/bash
set -e

# --- 1. CREATE HYPRLAND SESSION ---
# Manually register the session in case the package didn't
mkdir -p /usr/share/wayland-sessions
cat <<ENTRY > /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
ENTRY

# --- 2. ENABLE SERVICES ---
systemctl disable getty@tty2.service
systemctl enable ly@tty2.service
systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable fstrim.timer
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true

# --- 3. DETECT SENSORS ---
if [ -d /sys/class/dmi ]; then
    yes | sensors-detect --auto > /dev/null 2>&1 || true
fi









# ------------- REPLACE WITH AN APP LATER -------------
# System Config
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
# Theme, Icons & Cursor
mkdir -p /usr/share/glib-2.0/schemas/
cat <<CRS > /usr/share/glib-2.0/schemas/99_haremalos_defaults.gschema.override
[org.gnome.desktop.interface]
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Classic'
cursor-size=24
CRS
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Fonts
mkdir -p /usr/share/fonts/TTF
curl -L -o /usr/share/fonts/TTF/Monocraft.ttc https://github.com/IdreesInc/Monocraft/releases/latest/download/Monocraft.ttc
fc-cache -fv

# Binds
mkdir -p /etc/skel/Settings/Config/hypr
cat <<HYPR > /etc/skel/Settings/Config/hypr/hyprland.conf
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle
exec-once = hyprpaper
exec-once = hyprpanel
bind = SUPER, R, exec, hyprlauncher
bind = SUPER, SPACE, exec, wezterm
bind = PRINT, exec, hyprshot -m region
HYPR

# Yazi
mkdir -p /etc/skel/Settings/Config/yazi
cat <<YAZI > /etc/skel/Settings/Config/yazi/yazi.toml
[manager]
ratio          = [ 1, 3, 4 ]
show_hidden    = true
sort_by        = "natural"
[preview]
max_width      = 1280
max_height     = 720
image_delay    = 30
[opener]
play    = { run = 'mpv "\$@"', orphan = true, desc = "Play Video" }
copy    = { run = 'echo "\$@" | wl-copy', desc = "Copy Path" }
extract = { run = '7z x "\$@"', desc = "Extract Archive" }
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
run  = [ "copy path", "shell 'echo \"\$@\" | wl-copy' --confirm" ]
desc = "Copy path to system clipboard"
YAZIKEY

# Login Manager
mkdir -p /etc/ly
cat <<INI > /etc/ly/config.ini
[server]
session = hyprland
animation = 2
bigclock = true
[color]
bg = 0
fg = 5
INI
# -----------------------------------------------------
