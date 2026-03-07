#!/data/data/com.termux/files/usr/bin/bash
# Remove Docker, Debian chroot, and ext4 image
# Usage: su -c bash ~/uninstall.sh

DEBIAN=/data/local/dockerroot
IMG=/data/local/docker.img
BASH=/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR=$(dirname "$0")

$BASH "$SCRIPT_DIR/stop-docker.sh"

# Safety check: refuse to rm if mounts are still active
if mount | grep -q dockerroot; then
    echo "Error: mounts still active, aborting to prevent system freeze."
    mount | grep dockerroot
    exit 1
fi

echo "Removing..."
rm -f $IMG
rm -rf $DEBIAN

echo "Uninstalled."
