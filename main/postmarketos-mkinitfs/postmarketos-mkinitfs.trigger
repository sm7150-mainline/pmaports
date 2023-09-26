#!/bin/sh -e
# This script fails on error (-e). We don't want an error while generating the
# initramfs to go unnoticed, it may lead to the device not booting anymore.

# Only invoke mkinitfs if the deviceinfo exists in the rootfs
if [ -f /usr/share/deviceinfo/deviceinfo ]; then
	/usr/sbin/mkinitfs
fi
