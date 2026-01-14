#!/bin/bash
set -euo pipefail

# --- 1. PRE-FLIGHT ---
if [ ! -d /sys/firmware/efi ]; then echo "Error: UEFI required."; exit 1; fi

# --- 2. DISK SELECTION ---
lsblk -d -n -o NAME,SIZE,MODEL
read -p "TARGET DISK (e.g. sda or nvme0n1): " D_NAME
TARGET_DISK="/dev/${D_NAME#/dev/}"

# --- 3. SOFTWARE CHOICES ---
read -p "Is this a Dual Boot? (y/n): " IS_DB
read -p "Install Steam? (y/n) " I_STEAM
read -p "Install Toolbox? (y/n) " I_TOOLBOX
read -p "Install Blender? (y/n) " I_BLENDER
read -p "Install Unity? (y/n) " I_UNITY
read -p "Install OBS? (y/n) " I_OBS
read -p "Install Ardour? (y/n) " I_ARDOUR

# --- 4. DUAL BOOT ---
if [[ "$IS_DB" =~ [Yy] ]]; then
    source ./dual_boot.sh
else
    source ./single_boot.sh
fi

# --- 5. MOUNT & INSTALL ---
mount "$ROOT_P" /mnt
mkdir -p /mnt/boot /mnt/home
mount "$EFI_P" /mnt/boot
mount "$HOME_P" /mnt/home

pacstrap -K /mnt base linux linux-firmware sudo curl wget amd-ucode bash-completion --noconfirm --needed

# --- 6. CHROOT HANDOFF ---
genfstab -U /mnt >> /mnt/etc/fstab
cp system_setup.sh system_apps.sh system_config.sh /mnt/
chmod +x /mnt/*.sh
arch-chroot /mnt /bin/bash <<EOF
  export I_STEAM="${I_STEAM}"
  export I_TOOLBOX="${I_TOOLBOX}"
  export I_BLENDER="${I_BLENDER}"
  export I_UNITY="${I_UNITY}"
  export I_OBS="${I_OBS}"
  export I_ARDOUR="${I_ARDOUR}"
  ./system_setup.sh
  ./system_apps.sh
  ./system_config.sh
EOF

rm /mnt/*.sh
echo "SUCCESS: Fresh install complete."
