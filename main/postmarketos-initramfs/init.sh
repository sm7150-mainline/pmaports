#!/bin/sh
# shellcheck disable=SC1091

IN_CI="false"

[ -e /hooks/10-verbose-initfs.sh ] && set -x

[ -e /hooks/05-ci.sh ] && IN_CI="true"

[ -e /etc/unudhcpd.conf ] && . /etc/unudhcpd.conf
. ./init_functions.sh
. /usr/share/misc/source_deviceinfo
[ -e /etc/os-release ] && . /etc/os-release
# provide a default for os-release's VERSION in case the file doesn't exist
VERSION="${VERSION:-unknown}"

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
/bin/busybox --install -s
/bin/busybox-extras --install -s

# Mount everything, set up logging, modules, mdev
mount_proc_sys_dev
setup_log
setup_firmware_path

if [ "$IN_CI" = "false" ]; then
	# shellcheck disable=SC2154
	load_modules /lib/modules/initramfs.load "libcomposite"
	setup_framebuffer
	show_splash "Loading..."
	setup_mdev
	setup_dynamic_partitions "${deviceinfo_super_partitions:=}"
	mount_subpartitions
else
	# loads all modules
	setup_udev
fi
run_hooks /hooks

if [ "$IN_CI" = "true" ]; then
	echo "PMOS: CI tests done, disabling console and looping forever"
	dmesg -n 1
	loop_forever
fi

# Always run dhcp daemon/usb networking for now (later this should only
# be enabled, when having the debug-shell hook installed for debugging,
# or get activated after the initramfs is done with an OpenRC service).
setup_usb_network
start_unudhcpd

mount_boot_partition /boot
extract_initramfs_extra /boot/initramfs-extra
setup_udev
run_hooks /hooks-extra

wait_root_partition
delete_old_install_partition
resize_root_partition
unlock_root_partition
resize_root_filesystem
mount_root_partition

# Mount boot partition into sysroot, so OpenRC doesn't need to do it (#664)
umount /boot
mount_boot_partition /sysroot/boot "rw"

init="/sbin/init"
setup_bootchart2

# Switch root
killall telnetd mdev udevd msm-fb-refresher 2>/dev/null

# shellcheck disable=SC2093
exec switch_root /sysroot "$init"

echo "ERROR: switch_root failed!"
echo "Looping forever. Install and use the debug-shell hook to debug this."
echo "For more information, see <https://postmarketos.org/debug-shell>"
loop_forever
