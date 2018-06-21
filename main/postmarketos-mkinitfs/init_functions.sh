#!/bin/sh
# This file will be in /init_functions.sh inside the initramfs.
IP=172.16.42.1

# Redirect stdout and stderr to logfile
setup_log() {
	# Bail out if PMOS_NO_OUTPUT_REDIRECT is set
	echo "### postmarketOS initramfs ###"
	grep -q PMOS_NO_OUTPUT_REDIRECT /proc/cmdline && return

	# Print a message about what is going on to the normal output
	echo "NOTE: All output from the initramfs gets redirected to:"
	echo "/pmOS_init.log"
	echo "If you want to disable this behavior (e.g. because you're"
	echo "debugging over serial), please add this to your kernel"
	echo "command line: PMOS_NO_OUTPUT_REDIRECT"

	# Start redirect, print the first line again
	exec >/pmOS_init.log 2>&1
	echo "### postmarketOS initramfs ###"
}

mount_proc_sys_dev() {
	# mdev
	mount -t proc -o nodev,noexec,nosuid proc /proc
	mount -t sysfs -o nodev,noexec,nosuid sysfs /sys

	mkdir /config
	mount -t configfs -o nodev,noexec,nosuid configfs /config

	# /dev/pts (needed for telnet)
	mkdir -p /dev/pts
	mount -t devpts devpts /dev/pts
}

setup_mdev() {
	echo /sbin/mdev >/proc/sys/kernel/hotplug
	mdev -s
}

mount_subpartitions() {
	# Do not create subpartition mappings if pmOS_boot
	# already exists (e.g. installed on an sdcard)
	blkid |grep -q "pmOS_boot"  && return

	for i in /dev/mmcblk*; do
		case "$(kpartx -l "$i" 2>/dev/null | wc -l)" in
			2)
				echo "Mount subpartitions of $i"
				kpartx -afs "$i"
				# Ensure that this was the *correct* subpartition
				# Some devices have mmc partitions that appear to have
				# subpartitions, but aren't our subpartition.
				if blkid | grep -q "pmOS_boot"; then
					break
				fi
				kpartx -d "$i"
				continue
				;;
			*)
				continue
				;;
		esac
	done
}

find_root_partition() {
	# The partition layout is one of the following:
	# a) boot, root partitions on sdcard
	# b) boot, root partition on the "system" partition (which has its
	#    own partition header! so we have partitions on partitions!)
	#
	# mount_subpartitions() must get executed before calling
	# find_root_partition(), so partitions from b) also get found.

	# Try partitions in /dev/mapper and /dev/dm-* first
	for id in pmOS_root crypto_LUKS; do
		for path in /dev/mapper /dev/dm; do
			DEVICE="$(blkid | grep "$path" | grep "$id" \
				| cut -d ":" -f 1)"
			[ -z "$DEVICE" ] || break 2
		done
	done

	# Then try all devices
	if [ -z "$DEVICE" ]; then
		for id in pmOS_root crypto_LUKS; do
			DEVICE="$(blkid | grep "$id" | cut -d ":" -f 1)"
			[ -z "$DEVICE" ] || break
		done
	fi
	echo "$DEVICE"
}

find_boot_partition() {
	findfs LABEL="pmOS_boot"
}

mount_boot_partition() {
	partition=$(find_boot_partition)
	if [ -z "$partition" ]; then
		echo "ERROR: boot partition not found!"
		show_splash /splash-noboot.ppm.gz
		loop_forever
	fi
	echo "Mount boot partition ($partition)"
	mount -r "$partition" /boot
}

# $1: initramfs-extra path
extract_initramfs_extra() {
	initramfs_extra="$1"
	if [ ! -e "$initramfs_extra" ]; then
		echo "ERROR: initramfs-extra not found!"
		show_splash /splash-noinitramfsextra.ppm.gz
		loop_forever
	fi
	echo "Extract $initramfs_extra"
	gzip -d -c "$initramfs_extra" | cpio -i
}

wait_root_partition() {
	while [ -z "$(find_root_partition)" ]; do
		show_splash /splash-nosystem.ppm.gz
		echo "Could not find the root partition."
		echo "Maybe you need to insert the sdcard, if your device has"
		echo "any? Trying again in one second..."
		sleep 1
	done
}

resize_root_partition() {
	partition=$(find_root_partition)
	# Only resize the partition if it's inside the device-mapper, which means
	# that the partition is stored as a subpartition inside another one.
	# In this case we want to resize it to use all the unused space of the 
	# external partition.
	if [ -z "${partition##"/dev/mapper/"*}" ]; then
		# Get physical device
		partition_dev=$(dmsetup deps -o devname "$partition" | \
			awk -F "[()]" '{print "/dev/"$2}')
		# Check if there is unallocated space at the end of the device
		if parted -s "$partition_dev" print free | tail -n2 | \
			head -n1 | grep -qi "free space"; then
			echo "Resize root partition ($partition)"
			# unmount subpartition, resize and remount it
			kpartx -d "$partition"
			parted -s "$partition_dev" resizepart 2 100%
			kpartx -afs "$partition_dev"
		fi
	fi
	# Resize the root partition (non-subpartitions). Usually we do not want this,
	# except for QEMU devices (where PMOS_FORCE_PARTITION_RESIZE gets passed as
	# kernel parameter).
	if grep -q PMOS_FORCE_PARTITION_RESIZE /proc/cmdline; then
		echo "Resize root partition ($partition)"
		parted -s "$(echo "$partition" | sed -E 's/p?2$//')" resizepart 2 100%
		partprobe
	fi
}

unlock_root_partition() {
	partition="$(find_root_partition)"
	if cryptsetup isLuks "$partition"; then
		until cryptsetup status root | grep -qwi active; do
			start_onscreen_keyboard
		done
		# Show again the loading splashscreen
		show_splash /splash-loading.ppm.gz
	fi
}

resize_root_filesystem() {
	partition="$(find_root_partition)"
	touch /etc/mtab # see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=673323
	echo "Check/repair root filesystem ($partition)"
	e2fsck -f -y "$partition"
	echo "Resize root filesystem ($partition)"
	resize2fs -f "$partition"
}

mount_root_partition() {
	partition="$(find_root_partition)"
	echo "Mount root partition ($partition)"
	mount -t ext4 -o ro "$partition" /sysroot
	if ! [ -e /sysroot/usr ]; then
		echo "ERROR: unable to mount root partition!"
		show_splash /splash-mounterror.ppm.gz
		loop_forever
	fi
}

setup_usb_network_android() {
	# Only run, when we have the android usb driver
	SYS=/sys/class/android_usb/android0
	[ -e "$SYS" ] || return

	# Do the setup
	printf "%s" "0" >"$SYS/enable"
	printf "%s" "18D1" >"$SYS/idVendor"
	printf "%s" "D001" >"$SYS/idProduct"
	printf "%s" "rndis" >"$SYS/functions"
	printf "%s" "1" >"$SYS/enable"
}

setup_usb_network_configfs() {
	CONFIGFS=/config/usb_gadget
	[ -e "$CONFIGFS" ] || return

	mkdir $CONFIGFS/g1
	printf "%s" "18D1" >"$CONFIGFS/g1/idVendor"
	printf "%s" "D001" >"$CONFIGFS/g1/idProduct"

	mkdir $CONFIGFS/g1/strings/0x409

	mkdir $CONFIGFS/g1/functions/rndis.usb0

	mkdir $CONFIGFS/g1/configs/c.1
	mkdir $CONFIGFS/g1/configs/c.1/strings/0x409
	printf "%s" "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration

	ln -s $CONFIGFS/g1/functions/rndis.usb0 $CONFIGFS/g1/configs/c.1

	# See also: #338
	# shellcheck disable=SC2005
	echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC
}

setup_usb_network() {
	# Only run once
	_marker="/tmp/_setup_usb_network"
	[ -e "$_marker" ] && return
	touch "$_marker"
	echo "Setup usb network"
	# Run all usb network setup functions (add more below!)
	setup_usb_network_android
	setup_usb_network_configfs
}

start_udhcpd() {
	# Only run once
	[ -e /etc/udhcpd.conf ] && return

	# Skip if disabled
	# shellcheck disable=SC2154
	if [ "$deviceinfo_disable_dhcpd" = "true" ]; then
		echo "NOTE: start of dhcpd is disabled (deviceinfo_disable_dhcpd)"
		touch /etc/udhcpcd.conf
		return
	fi

	# Get usb interface
	INTERFACE=""
	ifconfig rndis0 "$IP" && INTERFACE=rndis0
	if [ -z $INTERFACE ]; then
		ifconfig usb0 "$IP" && INTERFACE=usb0
	fi
	if [ -z $INTERFACE ]; then
		ifconfig eth0 "$IP" && INTERFACE=eth0
	fi

	# Create /etc/udhcpd.conf
	{
		echo "start 172.16.42.2"
		echo "end 172.16.42.2"
		echo "auto_time 0"
		echo "decline_time 0"
		echo "conflict_time 0"
		echo "lease_file /var/udhcpd.leases"
		echo "interface $INTERFACE"
		echo "option subnet 255.255.255.0"
	} >/etc/udhcpd.conf

	echo "Start the dhcpcd daemon (forks into background)"
	udhcpd
}

setup_directfb_tslib(){
	# Set up directfb and tslib
	# Note: linux_input module is disabled since it will try to take over
	# the touchscreen device from tslib (e.g. on the N900)
	export DFBARGS="system=fbdev,no-cursor,disable-module=linux_input"
	# shellcheck disable=SC2154
	if [ ! -z "$deviceinfo_dev_touchscreen" ]; then
		export TSLIB_TSDEVICE="$deviceinfo_dev_touchscreen"
	fi
}

start_onscreen_keyboard(){
	setup_directfb_tslib
	osk-sdl -n root -d "$partition" -c /etc/osk.conf -v > /osk-sdl.log 2>&1
	unset DFBARGS
	unset TSLIB_TSDEVICE
}

start_charging_mode(){
	# Check cmdline for charging mode
	chargingmodes="
		androidboot.mode=charger
		lpm_boot=1
		androidboot.huawei_type=oem_rtc
		startup=0x00010004
		lpcharge=1
	"
	# shellcheck disable=SC2086
	grep -Eq "$(echo $chargingmodes | tr ' ' '|')" /proc/cmdline || return
	setup_directfb_tslib
	# Get the font from osk-sdl config
	fontpath=$(awk '/^keyboard-font/{print $3}' /etc/osk.conf)
	# Set up triggerhappy config
	{
		echo "KEY_POWER 1 pgrep -x charging-sdl || charging-sdl -pcf $fontpath"
	} >/etc/triggerhappy.conf
	# Start it once and then start triggerhappy
	charging-sdl -pcf "$fontpath" &
	thd --deviceglob /dev/input/event* --triggers /etc/triggerhappy.conf
}

# $1: path to ppm.gz file
show_splash() {
	gzip -c -d "$1" >/tmp/splash.ppm
	fbsplash -s /tmp/splash.ppm
}

set_framebuffer_mode() {
	[ -e "/sys/class/graphics/fb0/modes" ] || return
	[ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return

	_mode="$(cat /sys/class/graphics/fb0/modes)"
	echo "Setting framebuffer mode to: $_mode"
	echo "$_mode" > /sys/class/graphics/fb0/mode
}

loop_forever() {
	while true; do
		sleep 1
	done
}
