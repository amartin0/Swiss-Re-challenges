#!/bin/bash
# Script to prepare the server  


#####################################
# Add disk and migrate  /var/www/html
#####################################

set -e

# Check if device argument is provided
if [ -z "$1" ]; then
    echo "Usage: sudo $0 <disk-device> (e.g., /dev/sdb)"
    exit 1
fi

DISK="$1"
PARTITION="${DISK}1"

# Create GPT and partition if it does not exist
if ! lsblk -no NAME "$DISK" | grep -q "1"; then
    echo "Creating GPT partition table and primary partition on $DISK..."
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart primary ext4 0% 100%
    sleep 2
fi

# Format partition if no filesystem
echo "Formatting $PARTITION as ext4..."
mkfs.ext4 -F "$PARTITION"

# Temporary mount
TMP_MOUNT="/datadisk"
mkdir -p "$TMP_MOUNT"
mount "$PARTITION" "$TMP_MOUNT"

# Copy existing web content to new disk
echo "Copying /var/www/html to $TMP_MOUNT..."
rsync -a --remove-source-files /var/www/html/ "$TMP_MOUNT/"

# Remove empty directories left behind
find /var/www/html -type d -empty -delete

# Unmount temporary mount
umount "$TMP_MOUNT"

# Mount permanently at /var/www/html
mkdir -p /var/www/html
mount "$PARTITION" /var/www/html

# Get UUID of the partition
UUID=$(blkid -s UUID -o value "$PARTITION")

# Add entry to /etc/fstab if not already present
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID /var/www/html ext4 defaults 0 2" >> /etc/fstab
    echo "Added entry to /etc/fstab for persistent mount."
fi

echo "Disk $PARTITION is now mounted at /var/www/html and will persist across reboots."
