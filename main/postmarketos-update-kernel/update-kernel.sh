#!/bin/ash
# shellcheck shell=dash
set -e

case $1 in
	--help|-h|'')
		echo "Usage: pmos-update-kernel [flavor]"
		exit 1
		;;
esac

# shellcheck disable=SC1091
. /etc/deviceinfo

FLAVOR=$1
METHOD=${deviceinfo_flash_methods:?}
case $METHOD in
	fastboot|heimdall-bootimg)
		BOOT_PARTITION=$(findfs PARTLABEL="boot")
		echo "Flashing boot.img..."
		dd if=/boot/boot.img-"$FLAVOR" of="$BOOT_PARTITION" bs=1M
		;;
	heimdall-isorec)
		KERNEL_PARTITION=$(findfs PARTLABEL="${deviceinfo_flash_heimdall_partition_kernel:?}")
		INITFS_PARTITION=$(findfs PARTLABEL="${deviceinfo_flash_heimdall_partition_initfs:?}")
		echo "Flashing kernel..."
		dd if=/boot/vmlinuz-"$FLAVOR" of="$KERNEL_PARTITION" bs=1M
		echo "Flashing initramfs..."
		gunzip -c /boot/initramfs-"$FLAVOR" | lzop | dd of="$INITFS_PARTITION" bs=1M
		;;
	0xffff)
		echo -n "No need to use this utility, since uboot loads the kernel directly from"
		echo " the boot partition. Your kernel should be updated already."
		exit 1
		;;
	*)
		echo "Devices with flash method: $METHOD are not supported."
		exit 1
		;;
esac
echo "Done."
