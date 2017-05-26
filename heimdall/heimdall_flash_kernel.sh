#!/bin/sh
set -e

usage()
{
	echo "Flash an initramfs file to the recovery partition, and flash a kernel."
	echo "The kernel needs to have its own minimal initramfs, that loads the"
	echo "real initramfs from the recovery partition (\"isorec\")."
	echo ""
	echo "Usage: $(basename "$0") <initramfs> <kernel>"
	exit 1
}

# Sanity checks
[ "$#" != 2 ] && usage
INITRAMFS="$1"
KERNEL="$2"
for file in "$INITRAMFS" "$KERNEL"; do
	[ -e "$file" ] && continue
	echo "ERROR: File $file does not exist!"
	exit 1
done

echo "(1/2) flash initramfs to recovery partition (isorec-style)"
heimdall_wait_for_device.sh
gunzip -c "$INITRAMFS" | lzop > /tmp/initramfs.lzo
heimdall flash --RECOVERY /tmp/initramfs.lzo
rm /tmp/initramfs.lzo

sleep 20
echo "(2/2) flash kernel (hit ^C if you only wanted to flash initramfs)"
heimdall_wait_for_device.sh
heimdall flash --KERNEL "$KERNEL"
