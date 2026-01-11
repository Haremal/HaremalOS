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

# Enable OS Prober and Kill Nvidia
sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm amdgpu.dc=1"/' /etc/default/grub

# OS Prober Manual Scan Fix
mkdir -p /mnt_temp
for part in $(lsblk -no NAME,FSTYPE | grep -E 'ntfs|vfat|ext4' | awk '{print $1}'); do
    mount /dev/$part /mnt_temp 2>/dev/null && echo "Scanning /dev/$part..." || continue
done

# Hardware Install
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Cleanup
umount /mnt_temp 2>/dev/null || true
rmdir /mnt_temp

# --- 3. SWAP FILE ---
if [ ! -f /swapfile ]; then
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    # Note: swapon might fail in some chroot environments; fstab handles it on reboot
    swapon /swapfile
    echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi
