#!/bin/sh -e

# $1: kernel flavor
rebuild_initfs_flavor()
{
	abi_release=$(cat /usr/share/kernel/"$1"/kernel.release)
	mkinitfs -o /boot/initramfs-"$1" "$abi_release"
}

# Each argument to this shell script is a path, that caused the trigger to
# execute. When a hook was changed, rebuild all flavors. When only one flavor
# was changed, find out if it has been installed or uninstalled, and rebuild
# it or delete the left-overs.
rebuild_all="false"
for i in "$@"; do
	case "$i" in
		# Hook change
		/etc/postmarketos-mkinitfs/hooks*)
			rebuild_all="true"
			break ;;

		# Kernel flavor change
		/usr/share/kernel/*)
			flavor=${i##*/}
			if [ -f "$i"/kernel.release ]; then
				# installed
				[ "$rebuild_all" = "true" ] || rebuild_initfs_flavor "$flavor"
			else
				# uninstalled
				rm -f "$( readlink -f /boot/initramfs-"$flavor" )" \
					/boot/initramfs-"$flavor" /boot/vmlinuz-"$flavor" \
					/boot/"$flavor" /boot/"$flavor".gz /"$flavor" /"$flavor".gz
			fi

			break ;;
	esac
done

# Rebuild all flavors, if necessary
if [ "$rebuild_all" = "true" ]; then
	for i in /usr/share/kernel/*; do
		[ -d "$i" ] && rebuild_initfs_flavor "${i##*/}"
	done
fi

# Cleanup unused initramfs
for i in /boot/initramfs-[0-9]*; do
	[ -f "$i" ] || continue
	if ! [ -f /boot/vmlinuz-"${i#/boot/initramfs-}" ]; then
		rm "$i"
	fi
done

sync
exit 0
