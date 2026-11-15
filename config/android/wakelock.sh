#!/system/bin/sh
# Magisk runs this file at every boot from /data/adb/service.d.
# Keep the CPU awake, so that SSH into Kali and Docker containers answer when the screen is off.
# This uses more battery.
echo kali-ssh > /sys/power/wake_lock
