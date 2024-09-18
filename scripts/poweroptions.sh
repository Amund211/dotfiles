#! /usr/bin/bash

# Optionally pass screenlocker as only argument

options="Nothing\nShutdown\nReboot\nDisk-suspend\nHybrid-suspend\nRAM-suspend\nUEFI/BIOS\nWindows"

chosen=$(echo -e "$options" | dmenu -i -p "What action to perform?")

case "$chosen" in
Nothing) : ;;
Shutdown) shutdown -h now ;;
Reboot) reboot ;;
Disk-suspend) eval "$1" && systemctl hibernate ;;
Hybrid-suspend) eval "$1" && systemctl hybrid-sleep ;;
RAM-suspend) eval "$1" && systemctl suspend ;;
UEFI/BIOS) systemctl reboot --firmware-setup ;;
Windows) sudo -n efibootmgr -n "$(efibootmgr | grep Windows | sed -e 's/\*.*//' -e 's/Boot//' -e '1q')" && reboot ;;
esac
