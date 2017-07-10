#!/bin/sh
set -e

usage()
{
	echo "Flash initramfs and kernel to separate partitions."
	echo "The kernel needs to have its own minimal initramfs, that loads the"
	echo "real initramfs from the other partition (\"isorec\")."
	echo ""
	echo "Usage: $(basename "$0") <initfs> <initfs partition> <kernel> <kernel partition>"
	exit 1
}

# Sanity checks
[ "$#" != 4 ] && usage
INITFS="$1"
INITFS_PARTITION="$2"
KERNEL="$3"
KERNEL_PARTITION="$4"
for file in "$INITFS" "$KERNEL"; do
	[ -e "$file" ] && continue
	echo "ERROR: File $file does not exist!"
	exit 1
done

echo "(1/2) Flash initramfs to the '$INITFS_PARTITION' partition (isorec-style)"
heimdall_wait_for_device.sh
gunzip -c "$INITFS" | lzop > /tmp/initramfs.lzo
heimdall flash --"$INITFS_PARTITION" /tmp/initramfs.lzo
rm /tmp/initramfs.lzo

# Sleeping is necessary here, because when directly connecting again, the
# flashing of the kernel has always failed (at least on the i9100).
echo "Sleeping for 20 seconds..."
sleep 20

echo "(2/2) Flash kernel to the '$KERNEL_PARTITION' partition"
echo "NOTE: Press ^C if you only wanted to flash the initramfs."
heimdall_wait_for_device.sh
heimdall flash --"$KERNEL_PARTITION" "$KERNEL"
