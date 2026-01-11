#!/bin/bash
set -e

# --- 1. KEYRING & REPOS ---
pacman-key --init
pacman-key --populate archlinux
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# --- 2. GRUB & BOOTLOADER ---
pacman -S --noconfirm --needed grub efibootmgr
BOOT_PKGS="grub efibootmgr"
if [ -f /tmp/dual_boot_flag ]; then
    BOOT_PKGS="$BOOT_PKGS os-prober ntfs-3g"
fi
pacman -S --noconfirm --needed $BOOT_PKGS
sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub
if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi
for part in $(lsblk -no NAME,FSTYPE | grep -E 'ntfs|vfat|ext4' | awk '{print $1}'); do
    mkdir -p /mnt_temp
    mount /dev/$part /mnt_temp 2>/dev/null && echo "Scanning /dev/$part..." || continue
done

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
umount /mnt_temp 2>/dev/null || true

# --- 3. SWAP FILE ---
if [ ! -f /swapfile ]; then
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi
