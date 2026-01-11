#!/bin/bash
set -e

# --- 1. KEYRING & REPOS ---
pacman-key --init
pacman-key --populate archlinux
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# --- 2. GRUB & BOOTLOADER ---
BOOT_PKGS="grub efibootmgr"
[ -f /tmp/dual_boot_flag ] && PKGS="$PKGS os-prober ntfs-3g"
pacman -S --noconfirm --needed $BOOT_PKGS

# Enable OS Prober and Kill Nvidia
sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm amdgpu.dc=1"/' /etc/default/grub

# Hardware Install
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck

# Generate Config (os-prober runs here)
grub-mkconfig -o /boot/grub/grub.cfg

# --- 3. SWAP FILE ---
if [ ! -f /swapfile ]; then
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile || true
    echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi
