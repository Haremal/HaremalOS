# --- 1. DETECT EXISTING EFI ---
EFI_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "c12a7328" | awk '{print $1}' | head -n 1)
if [ -z "$EFI_P" ]; then
    echo "ERROR: No EFI partition found on $TARGET_DISK."
    echo "Dual Boot requires an existing EFI partition (like Windows)."
    exit 1
fi
echo "Found existing EFI partition: $EFI_P"

# --- 2. SEARCH FOR EXISTING LINUX ---
ROOT_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "4f680000-0044-4453-8061-616362657266" | awk '{print $1}' | tail -n 1) || true
HOME_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "0fc63daf-8483-4772-8e79-3d69d8477de4" | awk '{print $1}' | tail -n 1) || true

# --- 3. IF NOT FOUND, CREATE THEM ---
if [ "$FORMAT" == "1" ]; then
    sfdisk "$TARGET_DISK" << EOF
, $ROOT_SIZE, 4F680000-0044-4453-8061-616362657266
, , 0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
    udevadm settle
    ROOT_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "4f680000-0044-4453-8061-616362657266" | awk '{print $1}' | tail -n 1)
    HOME_P=$(lsblk "$TARGET_DISK" -no PATH,PARTTYPE | grep -i "0fc63daf-8483-4772-8e79-3d69d8477de4" | awk '{print $1}' | tail -n 1)
else
	echo "Existing Linux partitions found. Re-using $ROOT_P and $HOME_P."
fi

# --- 4. DETECT NEW PARTITIONS ---
echo "Identified ROOT: $ROOT_P"
echo "Identified HOME: $HOME_P"
read -p "Do you wish to continue? (y/n): " CONFIRM_PARTS
[[ "$CONFIRM_PARTS" != "y" ]] && exit 1

# --- 5. FORMATTING ---
mkfs.ext4 -F "$ROOT_P"
[[ "$FORMAT_HOME" =~ [Yy] ]] && mkfs.ext4 -F "$HOME_P"
