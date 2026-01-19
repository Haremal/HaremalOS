#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
chmod +x ./*.sh

# --- 1. PRE-FLIGHT ---
if [ ! -d /sys/firmware/efi ]; then echo "Error: UEFI required."; exit 1; fi
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

# --- 2. DISK SELECTION ---
lsblk -d -n -o NAME,SIZE,MODEL
read -p "TARGET DISK (e.g. /dev/sda or /dev/nvme0n1): " TARGET_DISK

# --- 3. MODE SELECTION ---
echo "1. FRESH INSTALL (Wipes ENTIRE Disk - New Partitions)"
echo "2. REUSE PARTITIONS (Keeps /home data safe)"
read -p "Select Mode (1 or 2): " INSTALL_MODE

if [[ "$INSTALL_MODE" == "1" ]]; then
    read -p "Enter Root partition size (e.g., 50G): " ROOT_SIZE
fi

# --- 4. SOFTWARE CHOICES ---
read -p "Install Steam? (y/n) " I_STEAM
read -p "Install Blender? (y/n) " I_BLENDER
read -p "Install OBS? (y/n) " I_OBS
read -p "Install Ardour? (y/n) " I_ARDOUR

# --- 5. PARTITIONING (FRESH INSTALL ONLY) ---
if [[ "$INSTALL_MODE" == "1" ]]; then
    echo "WARNING: ALL DATA ON $TARGET_DISK WILL BE DESTROYED."
    read -p "Type 'YES' to confirm: " CONFIRM
    [[ "$CONFIRM" != "YES" ]] && exit 1

    sfdisk --force "$TARGET_DISK" << EOF
label: gpt
size=512M, type=uefi
size=$ROOT_SIZE, type=linux
type=linux
EOF
    udevadm settle
    partprobe "$TARGET_DISK"
fi

# --- 6. MANUAL ASSIGNMENT ---
# We do this AFTER sfdisk so you see the REAL partitions
lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,PARTLABEL,PARTTYPENAME
echo "-------------------------------------------------------"
echo "IDENTIFY YOUR PARTITIONS"
echo "-------------------------------------------------------"
read -p "Type the EFI partition (e.g., /dev/sda1): " EFI_P
read -p "Type the ROOT partition (e.g., /dev/sda2): " ROOT_P
read -p "Type the HOME partition (e.g., /dev/sda3): " HOME_P

read -p "Do you want to format/wipe the HOME partition? (y/n): " WIPE_HOME
read -p "TYPE 'YES' TO CONTINUE AND APPLY CHANGES TO $TARGET_DISK: " FINAL_CHECK
[[ "$FINAL_CHECK" != "YES" ]] && exit 1

# --- 7. FORMATTING ---
# Always format EFI and Root on install
wipefs -af "$ROOT_P"
mkfs.ext4 -F "$ROOT_P"

# Only format Home if it's a Fresh Install (Mode 1)
if [[ "$INSTALL_MODE" == "1" ]]; then
    wipefs -af "$EFI_P"
    wipefs -af "$HOME_P"
    mkfs.fat -F 32 "$EFI_P"
    mkfs.ext4 -F "$HOME_P"
fi

if [[ "$WIPE_HOME" == "y" ]]; then
    wipefs -af "$HOME_P"
    mkfs.ext4 -F "$HOME_P"
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
  /system_setup.sh
  /system_apps.sh
  /system_config.sh
EOF

rm /mnt/*.sh
echo "SUCCESS: Fresh install complete."
