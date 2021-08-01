#!/bin/sh

# Declare used deviceinfo variables to pass shellcheck (order alphabetically)
deviceinfo_append_dtb=""
deviceinfo_arch=""
deviceinfo_bootimg_append_seandroidenforce=""
deviceinfo_bootimg_blobpack=""
deviceinfo_bootimg_dtb_second=""
deviceinfo_bootimg_mtk_mkimage=""
deviceinfo_bootimg_pxa=""
deviceinfo_bootimg_qcdt=""
deviceinfo_dtb=""
deviceinfo_flash_offset_base=""
deviceinfo_flash_offset_kernel=""
deviceinfo_flash_offset_ramdisk=""
deviceinfo_flash_offset_second=""
deviceinfo_flash_offset_tags=""
deviceinfo_flash_pagesize=""
deviceinfo_generate_bootimg=""
deviceinfo_generate_legacy_uboot_initfs=""
deviceinfo_mesa_driver=""
deviceinfo_mkinitfs_postprocess=""
deviceinfo_initfs_compression=""
deviceinfo_kernel_cmdline=""
deviceinfo_legacy_uboot_load_address=""
deviceinfo_modules_initfs=""
deviceinfo_flash_kernel_on_update=""

# Overwritten by mkinitfs.sh
tmpdir=""

source_deviceinfo()
{
	if [ ! -e "/etc/deviceinfo" ]; then
		echo "NOTE: deviceinfo (from device package) not installed yet," \
			"not building the initramfs now (it should get built later" \
			"automatically.)"
		exit 0
	fi
	# shellcheck disable=SC1091
	. /etc/deviceinfo
}

parse_commandline()
{
	if [ "$1" != "-o" ]; then
		echo "postmarketos-mkinitfs"
		echo "usage: $(basename "$0") -o OUTFILE KERNELVERSION"
		exit 1
	fi

	outfile=$2
	outfile_extra=$2-extra
	kernel=$3
}

# Verify that each file required by the installed hooks exists and exit with an
# error if they don't.
check_hook_files()
{
	for file in "/etc/postmarketos-mkinitfs/files"/*.files; do
		[ -f "$file" ] || continue
		while IFS= read -r line; do
			if ! [ -f "$line" ]; then
				echo "ERROR: File ${line} specified in ${file} does not exist!"
				exit 1
			fi
		done < "$file"
	done
}

create_folders()
{
	for dir in /bin /sbin /usr/bin /usr/sbin /proc /sys /dev /tmp /lib \
		/boot /sysroot /etc; do
		mkdir -p "$tmpdir$dir"
	done
}

get_modules_by_globs()
{
	globs="
		# base.modules
		kernel/drivers/block/loop.ko
		kernel/fs/overlayfs

		# cryptsetup.modules
		kernel/crypto/*
		kernel/arch/*/crypto/*
		kernel/drivers/md/dm-crypt.ko

		# required for modprobe
		modules.*
	"

	for glob in $globs; do
		for file in /lib/modules/$kernel/$glob; do
			if [ -d "$file" ]; then
				find "$file" -type f
			elif [ -e "$file" ]; then
				echo "$file"
			fi
		done
	done
}

# Read a modules-load.d style file into a single line. The file is expected to
# have empty lines, lines starting with "#" that are comments or one word in
# the line. The resulting parsed line is printed to stdout.
# $1: file to parse
parse_file_as_line()
{
	_first="true"
	while IFS= read -r line; do
		case "$line" in
			""|"#"*)
				# Comment or empty line, ignore
				;;
			*)
				if [ "$_first" = "true" ]; then
					_first="false"
				else
					printf " "
				fi
				printf "%s" "$line"
				;;
		esac
	done < "$1"
}

# Parse modules by name from deviceinfo and from these files:
# /etc/postmarketos-mkinitfs/modules/*.modules. The postmarketos-mkinitfs
# package installs a 00-default.modules there.
# Resolved kernel module paths get printed to stdout, informative logging to
# stderr.
# NOTE: This does not work with busybox' modprobe. That's why
#       postmarketos-mkinitfs depends on kmod.
get_modules_by_name()
{
	{
		echo "Scanning kernel module dependencies..."
		echo "NOTE: ** modprobe warnings below can be ignored ** if your device does not run the"
		echo "mainline kernel yet (most devices!) or if the related kernel options are enabled"
		echo "with 'y' instead of 'm' (module)."
	} >&2

	MODULES="$deviceinfo_modules_initfs"
	echo " - deviceinfo: $deviceinfo_modules_initfs" >&2

	for file in "/etc/postmarketos-mkinitfs/modules/"*.modules; do
		[ -f "$file" ] || continue
		_modules_file="$(parse_file_as_line "$file")"
		echo " - $(basename "$file"): $_modules_file" >&2
		MODULES="$MODULES $_modules_file"
	done

	# shellcheck disable=SC2086
	modprobe \
		-a \
		--dry-run \
		--show-depends \
		--set-version="$kernel" \
		$MODULES \
		| sort -u \
		| cut -d ' ' -f 2
}

get_modules()
{
	get_modules_by_globs
	get_modules_by_name
}

# Get the paths to all binaries and their dependencies
get_binaries()
{
	BINARIES="
		/bin/busybox
		/bin/busybox-extras
		/usr/sbin/telnetd
		/sbin/kpartx
	"

	for file in "/etc/postmarketos-mkinitfs/files"/*.files; do
		[ -f "$file" ] || continue
		while IFS= read -r line; do
			BINARIES="${BINARIES} ${line}"
		done < "$file"
	done
	# shellcheck disable=SC2086
	sudo -u nobody lddtree -l $BINARIES | sort -u
}

# Collect non-binary files for osk-sdl and its dependencies
# This gets called as $(get_osk_config), so the exit code can be checked/handled.
get_osk_config()
{
	fontpath=$(awk '/^keyboard-font = /{print $3}' /etc/osk.conf)
	if [ ! -f "$fontpath" ]; then
		echo "ERROR: failed to parse 'keyboard-font' from osk-sdl config!"
		exit 1
	fi
	ret="
		/etc/osk.conf
		/etc/ts.conf
		/etc/pointercal
		/etc/fb.modes
		/etc/directfbrc
		$fontpath
	"
	echo "${ret}"
}

get_binaries_extra()
{
	BINARIES_EXTRA="
		/lib/libz.so.1
		/sbin/dmsetup
		/sbin/e2fsck
		/usr/sbin/parted
		/usr/sbin/resize2fs
		/usr/sbin/resize.f2fs
	"

	if [ -x /usr/bin/osk-sdl ]; then
		BINARIES_EXTRA="
			$BINARIES_EXTRA
			$(find /usr/lib/directfb-* -name '*.so')
			/usr/bin/osk-sdl
			/sbin/cryptsetup
			/usr/lib/libGL.so.1
			/usr/lib/libts*
			/usr/lib/ts/*
		"
		if [ -n "$deviceinfo_mesa_driver" ]; then
			BINARIES_EXTRA="
				$BINARIES_EXTRA
				/usr/lib/libEGL.so.1
				/usr/lib/libGLESv2.so.2
				/usr/lib/libgbm.so.1
				/usr/lib/libudev.so.1
				/usr/lib/xorg/modules/dri/${deviceinfo_mesa_driver}_dri.so
			"
		fi
	fi

	tmp1=$(mktemp /tmp/mkinitfs.XXXXXX)
	get_binaries > "$tmp1"
	tmp2=$(mktemp /tmp/mkinitfs.XXXXXX)

	# shellcheck disable=SC2086
	sudo -u nobody lddtree -l $BINARIES_EXTRA | sort -u > "$tmp2"
	ret=$(comm -13 "$tmp1" "$tmp2")
	rm "$tmp1" "$tmp2"
	echo "${ret}"
}

# Copy files to the destination specified
# $1: files
# $2: destination
copy_files()
{
	for file in $1; do
		[ -e "$file" ] || continue
		cp -a --parents "$file" "$2"
	done
}

create_device_nodes()
{
	mknod -m 666 "$tmpdir/dev/null" c 1 3
	mknod -m 644 "$tmpdir/dev/random" c 1 8
	mknod -m 644 "$tmpdir/dev/urandom" c 1 9
}

replace_init_variables()
{
	sed -i "s:@INITRAMFS_EXTRA@:${outfile_extra}:g" "$tmpdir/init"
}

# Create a cpio image of the specified folder
# $1: folder
# $2: outfile
create_cpio_image()
{
	if ! cd "$1"; then
		echo "ERROR: failed to cd to '$1'"
		exit 1
	fi
	[ -z "$deviceinfo_initfs_compression" ] && deviceinfo_initfs_compression='gzip -1'
	find . -print0 \
		| cpio --quiet -o -0 -H newc \
		| $deviceinfo_initfs_compression > "$2"
}

# Required command check with useful error message
# $1: command (e.g. "mkimage")
# $2: package (e.g. "u-boot-tools")
# $3: related deviceinfo variable (e.g. "generate_bootimg")
require_package()
{
	[ "$(command -v "$1")" = "" ] || return
	echo "ERROR: 'deviceinfo_$3' is set, but the package '$2' was not"
	echo "installed! Please add '$2' to the depends= line of your device's"
	echo "APKBUILD. See also: <https://postmarketos.org/deviceinfo>"
	exit 1
}

# Legacy u-boot images
create_uboot_files()
{
	arch="arm"
	if [ "${deviceinfo_arch}" = "aarch64" ]; then
		arch="arm64"
	fi

	[ "${deviceinfo_generate_legacy_uboot_initfs}" = "true" ] || return
	require_package "mkimage" "u-boot-tools" "generate_legacy_uboot_initfs"

	echo "==> initramfs: creating uInitrd"
	# shellcheck disable=SC3060
	mkimage -A $arch -T ramdisk -C none -n uInitrd -d "$outfile" \
		"${outfile/initramfs-/uInitrd-}" || exit 1

	echo "==> kernel: creating uImage"
	# shellcheck disable=SC3060
	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ "${deviceinfo_append_dtb}" = "true" ]; then
		kernelfile="${kernelfile}-dtb"
	fi

	if [ -z "$deviceinfo_legacy_uboot_load_address" ]; then
		deviceinfo_legacy_uboot_load_address="80008000"
	fi

	# shellcheck disable=SC3060
	mkimage -A $arch -O linux -T kernel -C none -a "$deviceinfo_legacy_uboot_load_address" \
		-e "$deviceinfo_legacy_uboot_load_address" \
		-n postmarketos -d "$kernelfile" "${outfile/initramfs-/uImage-}" || exit 1
}

# Android devices
create_bootimg()
{
	[ "${deviceinfo_generate_bootimg}" = "true" ] || return
	# shellcheck disable=SC3060
	bootimg="${outfile/initramfs-/boot.img-}"

	if [ "${deviceinfo_bootimg_pxa}" = "true" ]; then
		require_package "pxa-mkbootimg" "pxa-mkbootimg" "bootimg_pxa"
		MKBOOTIMG=pxa-mkbootimg
	else
		require_package "mkbootimg-osm0sis" "mkbootimg" "generate_bootimg"
		MKBOOTIMG=mkbootimg-osm0sis
	fi

	echo "==> initramfs: creating boot.img"
	_base="${deviceinfo_flash_offset_base}"
	[ -z "$_base" ] && _base="0x10000000"

	# shellcheck disable=SC3060
	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ "${deviceinfo_append_dtb}" = "true" ]; then
		kernelfile="${kernelfile}-dtb"
	fi

	if [ "${deviceinfo_bootimg_mtk_mkimage}" = "true" ]; then
		kernelfile="${kernelfile}-mtk"
	fi

	_second=""
	if [ "${deviceinfo_bootimg_dtb_second}" = "true" ]; then
		if [ -z "${deviceinfo_dtb}" ]; then
			echo "ERROR: deviceinfo_bootimg_dtb_second is set, but"
			echo "'deviceinfo_dtb' is missing. Set 'deviceinfo_dtb'"
			echo "to the device tree blob for your device."
			echo "See also: <https://postmarketos.org/deviceinfo>"
			exit 1
		fi
		dtb="/usr/share/dtb/${deviceinfo_dtb}.dtb"
		_second="--second $dtb"
		if ! [ -e "$dtb" ]; then
			echo "ERROR: File not found: $dtb. Please set 'deviceinfo_dtb'"
			echo "to the relative path to the device tree blob for your"
			echo "device (without .dtb)."
			echo "See also: <https://postmarketos.org/deviceinfo>"
			exit 1
		fi
	fi
	_dt=""
	if [ "${deviceinfo_bootimg_qcdt}" = "true" ]; then
		_dt="--dt /boot/dt.img"
		if ! [ -e "/boot/dt.img" ]; then
			echo "ERROR: File not found: /boot/dt.img, but"
			echo "'deviceinfo_bootimg_qcdt' is set. Please verify that your"
			echo "device is a QCDT device by analyzing the boot.img file"
			echo "(e.g. 'pmbootstrap bootimg_analyze path/to/twrp.img')"
			echo "and based on that, set the deviceinfo variable to false or"
			echo "adjust your linux APKBUILD to properly generate the dt.img"
			echo "file. See also: <https://postmarketos.org/deviceinfo>"
			exit 1
		fi
	fi
	# shellcheck disable=SC2039 disable=SC2086
	"${MKBOOTIMG}" \
		--kernel "${kernelfile}" \
		--ramdisk "$outfile" \
		--base "${_base}" \
		--second_offset "${deviceinfo_flash_offset_second}" \
		--cmdline "${deviceinfo_kernel_cmdline}" \
		--kernel_offset "${deviceinfo_flash_offset_kernel}" \
		--ramdisk_offset "${deviceinfo_flash_offset_ramdisk}" \
		--tags_offset "${deviceinfo_flash_offset_tags}" \
		--pagesize "${deviceinfo_flash_pagesize}" \
		${_second} \
		${_dt} \
		-o "$bootimg" || exit 1
	if [ "${deviceinfo_mkinitfs_postprocess}" != "" ]; then
		sh "${deviceinfo_mkinitfs_postprocess}" "$outfile"
	fi
	if [ "${deviceinfo_bootimg_blobpack}" = "true" ] || [ "${deviceinfo_bootimg_blobpack}" = "sign" ]; then
		echo "==> initramfs: creating blob"
		_flags=""
		if [ "${deviceinfo_bootimg_blobpack}" = "sign" ]; then
			_flags="-s"
		fi
		# shellcheck disable=SC3060
		blobpack $_flags "${outfile/initramfs-/blob-}" \
				LNX "$bootimg" || exit 1
		# shellcheck disable=SC3060
		mv "${outfile/initramfs-/blob-}" "$bootimg"
	fi
	if [ "${deviceinfo_bootimg_append_seandroidenforce}" = "true" ]; then
		echo "==> initramfs: appending 'SEANDROIDENFORCE' to boot.img"
		# shellcheck disable=SC3037
		echo -n "SEANDROIDENFORCE" >> "$bootimg"
	fi
}

flash_updated_boot_parts()
{
	[ "${deviceinfo_flash_kernel_on_update}" = "true" ] || return
	# If postmarketos-update-kernel is not installed then nop
	[ -f /sbin/pmos-update-kernel ] || return
	if [ -f "/in-pmbootstrap" ]; then
		echo "==> Not flashing boot in chroot"
		return
	fi

	# We assume here that the device only has a single kernel
	# package installed and that it is also the one being upgraded.
	FLAVOR="$(basename "$(find /usr/share/kernel/* -type d -print -quit)")"

	if [ -z "$FLAVOR" ]; then
		echo "==> Couldn't determine flavor, are you running the stock kernel?"
		return
	fi

	echo "==> Flashing boot image flavor: $FLAVOR"
	
	pmos-update-kernel "$FLAVOR"
}

# Append the correct device tree to the linux image file or copy the dtb to the boot partition
append_or_copy_dtb()
{
	[ -n "${deviceinfo_dtb}" ] || return
	echo "==> kernel: device-tree blob operations"
	dtb=""
	for filename in $deviceinfo_dtb; do
		if ! [ -e "/usr/share/dtb/$filename.dtb" ]; then
			echo "ERROR: File not found: /usr/share/dtb/$filename.dtb"
			exit 1
		fi
		dtb="$dtb /usr/share/dtb/$filename.dtb"
	done
	# shellcheck disable=SC3060
	kernel="${outfile/initramfs-/vmlinuz-}"
	if [ "${deviceinfo_append_dtb}" = "true" ]; then
		echo "==> kernel: appending device-tree ${deviceinfo_dtb}"
		# shellcheck disable=SC2086
		cat "$kernel" $dtb > "${kernel}-dtb"
	else
		echo "==> kernel: copying dtb ${deviceinfo_dtb} to boot partition"
		# shellcheck disable=SC2086
		cp $dtb "$(dirname "${outfile}")"
	fi
}

# Add Mediatek header to kernel & initramfs
add_mtk_header()
{
	[ "${deviceinfo_bootimg_mtk_mkimage}" = "true" ] || return
	require_package "mtk-mkimage" "mtk-mkimage" "bootimg_mtk_mkimage"

	echo "==> initramfs: adding Mediatek header"
	mv "$outfile" "$outfile-orig"
	mtk-mkimage ROOTFS "$outfile-orig" "$outfile"
	rm "$outfile-orig"

	echo "==> kernel: adding Mediatek header"
	# shellcheck disable=SC3060
	kernel="${outfile/initramfs-/vmlinuz-}"
	rm -f "${kernel}-mtk"
	mtk-mkimage KERNEL "$kernel" "${kernel}-mtk"
}

# Create the initramfs-extra archive
# $1: outfile
generate_initramfs_extra()
{
	echo "==> initramfs: creating $1"

	osk_conf=""
	if [ -x /usr/bin/osk-sdl ]; then
		osk_conf="$(get_osk_config)"
		if [ $? -eq 1 ]; then
			echo "ERROR: Font specified in /etc/osk.conf does not exist!"
			exit 1
		fi
	fi

	# Set up initramfs-extra in temp folder
	tmpdir_extra=$(mktemp -d /tmp/mkinitfs.XXXXXX)
	tmpdir_extra_cpio=$(mktemp -d /tmp/mkinitfs-cpio.XXXXXX)
	tmpdir_extra_cpio_img="$tmpdir_extra_cpio/extra.img"
	mkdir -p "$tmpdir_extra"
	copy_files "$(get_binaries_extra)" "$tmpdir_extra"
	[ -n "$osk_conf" ] && copy_files "$osk_conf" "$tmpdir_extra"
	create_cpio_image "$tmpdir_extra" "$tmpdir_extra_cpio_img"
	rm -rf "$tmpdir_extra"

	# Replace old initramfs-extra *after* we are done to make sure
	# it does not become corrupted if something goes wrong.
	cp "$tmpdir_extra_cpio_img" "$1"
	rm -rf "$tmpdir_extra_cpio"
}
