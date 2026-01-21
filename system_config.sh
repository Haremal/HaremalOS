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

# --- 1. SET ENVIRONMENT VARIABLES ---
# Niri cannot set these inside config.kdl, so we use the standard pam_env method.
mkdir -p /etc/skel/Settings/Config/environment.d
cat <<ENV > /etc/skel/Settings/Config/environment.d/haermalos.conf
# Toolkits
GDK_BACKEND=wayland,x11
QT_QPA_PLATFORM=wayland;xcb
SDL_VIDEODRIVER=wayland
CLUTTER_BACKEND=wayland
# Theming
QT_QPA_PLATFORMTHEME=qt5ct
XCURSOR_THEME=Bibata-Modern-Classic
XCURSOR_SIZE=24
# Graphics (AMD Optimized)
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
mesa_glthread=true
ENV

# --- 2. NIRI CONFIGURATION ---
mkdir -p /etc/skel/.config/niri
cat <<NIRI > /etc/skel/.config/niri/config.kdl
// --- HAERMALOS NIRI CONFIG ---

input {
    keyboard {
        xkb {
            layout "us"
            // options "grp:win_space_toggle"
        }
    }
    touchpad {
        tap
        dwt
        natural-scroll
    }
}

output {
    // Defines the "First" monitor. 
    // Niri auto-detects, but this forces scale/res if needed.
    mode-action {
        // mode "1920x1080@144.000"
        scale 1.0
    }
}

layout {
    gaps 16
    center-focused-column "never"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    default-column-width { proportion 0.5; }

    focus-ring {
        width 2
        active-color "#7aa2f7"
        inactive-color "#565f89"
    }
}

// --- AUTOSTART ---
spawn-at-startup "swww-daemon"
spawn-at-startup "swww" "restore" // Restores previous wallpaper
spawn-at-startup "eww" "daemon"
spawn-at-startup "hypridle"
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"

// --- KEYBINDS ---
binds {
    // Basics
    Mod+Shift+E { quit; }
    Mod+Q { close-window; }
    Mod+Space { spawn "rio"; }
    Print { spawn "sh" "-c" "grim -g \"\$(slurp)\" - | wl-copy"; }
    XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+WheelScrollDown { focus-column-right; }
    Mod+WheelScrollUp   { focus-column-left; }
    Mod+Ctrl+Left  { move-column-left; }
    Mod+Ctrl+Right { move-column-right; }
    Mod+F { maximize-column; }
}
NIRI

# --- 3. CONFIG RUST ---
sudo mkdir -p /etc/skel/Settings/Config/helix /etc/skel/.cargo
cat<<RUST > /etc/skel/Settings/Config/helix/languages.toml
[[language]]
name = "rust"
auto-format = true
[language-server.rust-analyzer.config.check]
command = "clippy"
RUST
cat<<CARGO > /etc/skel/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
CARGO

# -----------------------------------------------------





# --- 1. CREATE NIRI SESSION ---
# Manually register the session in case the package didn't
mkdir -p /usr/share/wayland-sessions
cat <<ENTRY > /usr/share/wayland-sessions/niri.desktop
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
ENTRY

# --- 2. CONFIG LEMURS ---
cat <<SH > /etc/lemurs/wms/niri
exec niri-session
SH
chmod +x /etc/lemurs/wms/niri
# Lemurs usually just works, but we want it to allow root login 
mkdir -p /etc/lemurs
cat <<CONF > /etc/lemurs/config.toml
# HAREMALOS Lemurs Config
allow_empty_password = false
# This ensures it picks up our Niri script first
default_wm = "niri"
focus_username = true
CONF

# --- 3. ENABLE SERVICES ---
systemctl enable lemurs.service
systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable fstrim.timer
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true

# --- 4. DETECT SENSORS ---
if [ -d /sys/class/dmi ]; then
    yes | sensors-detect --auto > /dev/null 2>&1 || true
fi

# --- 5. FIRST BOOT ---
passwd -d root
chage -d 0 root
cat <<ISSUE > /etc/issue
------------------------------------------------------
      WELCOME TO HAREMALOS (FIRST BOOT)
------------------------------------------------------
Login as 'root' (No password required).
Then set password for root.

Then run:
1. useradd -m -c "Display Name" yourname
2. passwd yourname
3. rm /etc/issue && reboot

(This message will disappear after reboot)
------------------------------------------------------
ISSUE

