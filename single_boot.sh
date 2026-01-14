# --- 1. SAFETY CHECK ---
read -p "TYPE 'YES' TO CONTINUE $TARGET_DISK: " FINAL_CHECK
[[ "$FINAL_CHECK" != "YES" ]] && exit 1

# --- 2. CLEANUP & PARTITIONING ---
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

# --- 3. SEARCH OR CREATE ---
sleep 2
ROOT_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "4f680000-0044-4453-8061-616362657266" | awk '{print $1}' | tail -n 1) || true
if [ "$FORMAT" == "1" ]; then
    echo "Fresh install: Creating new partitions..."
    wipefs -a "$TARGET_DISK"
    sfdisk --force "$TARGET_DISK" << EOF
label: gpt
size=512M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
size=$ROOT_SIZE, type=4F680000-0044-4453-8061-616362657266
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
fi

udevadm settle
partprobe "$TARGET_DISK"
sleep 2

# --- 4. DEFINE & FORMAT ---
sleep 2
EFI_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "c12a7328" | awk '{print $1}' | head -n 1)
ROOT_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "4f680000-0044-4453-8061-616362657266" | awk '{print $1}' | tail -n 1)
HOME_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "0fc63daf-8483-4772-8e79-3d69d8477DE4" | awk '{print $1}' | tail -n 1)

# SAFETY GATE: for idiots
if [[ -z "$EFI_P" || -z "$ROOT_P" ]]; then
    echo "CRITICAL ERROR: Could not find partitions on $TARGET_DISK!"
    echo "If you chose Option 2, make sure the partitions actually exist first."
    lsblk "$TARGET_DISK"
    return 1 2>/dev/null || exit 1
fi

mkfs.fat -F 32 "$EFI_P"
mkfs.ext4 -F "$ROOT_P"
[[ "$FORMAT_HOME" =~ [Yy] ]] && mkfs.ext4 -F "$HOME_P"
