#!/bin/bash
set -e

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
monitor=,highres,auto,1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle
exec-once = hyprpaper
exec-once = hyprpanel
exec-once = eww daemon
bind = SUPER_L, SPACE, exec, foot
bind = , Print, exec, hyprshot -m region
# Volume Control (Wireplumber)
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
# Brightness Control (Brightnessctl)
bind = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
HYPR

# Login Manager
mkdir -p /etc/ly
cat <<INI > /etc/ly/config.ini
[server]
session = hyprland
animation = matrix
bigclock = true
hide_borders = false
[color]
bg = 0
fg = 6
[auth]
auth_root = true
INI
# -----------------------------------------------------





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
systemctl disable getty@tty2.service || true
systemctl enable ly@tty2.service
systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable fstrim.timer
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true

# --- 3. DETECT SENSORS ---
if [ -d /sys/class/dmi ]; then
    yes | sensors-detect --auto > /dev/null 2>&1 || true
fi

# --- 4. FIRST BOOT ---
passwd -d root
chage -d 0 root
cat <<ISSUE > /etc/issue
------------------------------------------------------
      WELCOME TO HAREMALOS (FIRST BOOT)
------------------------------------------------------
Login as 'root' (No password required).
Then set password to root (Forced action)

Then run:
1. useradd -m -c "Display Name" yourname
2. passwd yourname
3. rm /etc/issue && reboot

(This message will disappear after reboot)
------------------------------------------------------
ISSUE

