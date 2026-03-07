#!/data/data/com.termux/files/usr/bin/bash
# Remove Docker, Debian chroot, and ext4 image
# Usage: su -c bash ~/uninstall.sh

SCRIPT_DIR=$(dirname "$0")

# Stop Docker and unmount everything first
bash "$SCRIPT_DIR/stop-docker.sh"

echo "Removing image and chroot..."
rm -rf /data/local/dockerroot
rm -f /data/local/docker.img

echo "Uninstalled."
