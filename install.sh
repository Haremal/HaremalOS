#!/bin/bash
set -euo pipefail

# 1. PRE-FLIGHT CHECKS
if [ ! -d /sys/firmware/efi ]; then echo "Error: UEFI required."; exit 1; fi
ping -c 1 archlinux.org >/dev/null 2>&1 || { echo "Error: No internet."; exit 1; }

# 2. DISK SELECTION
lsblk -d -n -o NAME,SIZE,MODEL
read -p "Type your disk name (e.g., sda or nvme0n1): " D_NAME
TARGET_DISK="/dev/${D_NAME#/dev/}" # Cleans input if you accidentally type /dev/sda

# 3 DETECTION
echo "Scanning for other operating systems..."
OS_FOUND=$(os-prober || true)
DUAL_BOOT=false
[[ "$OS_FOUND" == *"Windows"* ]] && DUAL_BOOT=true

# 4 PRE-PARTITION CLEANUP (The "Disk in use" fix)
echo "Ensuring disk is not busy..."
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
# Nuke old signatures so sfdisk doesn't complain
wipefs -a "$TARGET_DISK"
udevadm settle

# 5. AUTOMATIC PARTITIONING
echo "Partitioning $TARGET_DISK..."
sfdisk "$TARGET_DISK" << EOF
label: gpt
size=512M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
size=100G, type=4F680000-0044-4453-8061-616362657266
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

# Give the kernel a second to "see" the new partitions
udevadm settle

# 6. AUTO-DETECTION OF PARTITION NAMES
PART_PREFIX=""
if [[ "$TARGET_DISK" == *"nvme"* ]]; then PART_PREFIX="p"; fi

EFI_P="${TARGET_DISK}${PART_PREFIX}1"
ROOT_P="${TARGET_DISK}${PART_PREFIX}2"
HOME_P="${TARGET_DISK}${PART_PREFIX}3"

echo "------------------------------------------------------"
echo "TARGET: EFI:$EFI_P | ROOT:$ROOT_P | HOME:$HOME_P"
echo "------------------------------------------------------"
read -p "Are you 100% sure? Type 'YES': " FINAL_CONFIRM
[[ "$FINAL_CONFIRM" != "YES" ]] && exit 1

read -p "Format efi ($EFI_P)? (y/n): " EFI_CONFIRM
read -p "Format home ($HOME_P)? (y/n): " HOME_CONFIRM

read -p "Install Steam? (y/n) " I_STEAM
read -p "Install Blender? (y/n) " I_BLENDER
read -p "Install Reaper? (y/n) " I_REAPER
read -p "Install OBS Studio? (y/n) " I_OBS
read -p "Install Unity Hub? (y/n) " I_UNITY

# 7. FORMATTING (Fixed path variables)
echo "Formatting started..."
if [[ "$EFI_CONFIRM" =~ [Yy] ]]; then
    mkfs.fat -F 32 "$EFI_P"
fi

mkfs.ext4 -F "$ROOT_P"

if [[ "$HOME_CONFIRM" =~ [Yy] ]]; then
    mkfs.ext4 -F "$HOME_P"
fi

# 8. MOUNTING (Cleaned path variables)
mount "$ROOT_P" /mnt
mkdir -p /mnt/boot /mnt/home
mount "$EFI_P" /mnt/boot
mount "$HOME_P" /mnt/home

echo "SUCCESS: Partitions mounted to /mnt"

# 9. INSTALLATION (The "Everything" List)
pacstrap -K /mnt base linux linux-firmware sudo curl wget amd-ucode bash-completion --noconfirm --needed

# 10. SYSTEM CONFIG
genfstab -U /mnt >> /mnt/etc/fstab

# 11. We must pass the Dual Boot status into the chroot via a file
if [ "$DUAL_BOOT" = true ]; then
    mkdir -p /mnt/tmp
    touch /mnt/tmp/dual_boot_flag
    echo "Dual Boot flag passed to installation environment."
fi

# 12. CHROOT
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/system_setup.sh" /mnt/
cp "$SCRIPT_DIR/system_apps.sh" /mnt/
cp "$SCRIPT_DIR/system_config.sh" /mnt/
chmod +x /mnt/*.sh
arch-chroot /mnt /bin/bash <<EOF
  export DUAL_BOOT='$DUAL_BOOT'
  export I_STEAM='$I_STEAM'
  export I_BLENDER='$I_BLENDER'
  export I_REAPER='$I_REAPER'
  export I_OBS='$I_OBS'
  export I_UNITY='$I_UNITY'
  ./system_setup.sh
  ./system_apps.sh
  ./system_config.sh
EOF
rm /mnt/*.sh

# TODO pacman -U --noconfirm --needed [github-haremal-browser-release]
# TODO pacman -U --noconfirm --needed [github-haremalos-manager-release]
# TODO exec-once = haremalos-manager
