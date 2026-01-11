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
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub
if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

# --- 3. SWAP FILE ---
if [ ! -f /swapfile ]; then
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi

# --- 4. PERMISSIONS ---
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd
chmod 440 /etc/sudoers.d/wheel-nopasswd

