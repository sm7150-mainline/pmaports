#!/bin/sh

source_deviceinfo()
{
	if [ ! -e "/etc/deviceinfo" ]; then
		echo "NOTE: deviceinfo (from device package) not installed yet," \
			"not building the initramfs now (it should get built later" \
			"automatically.)"
		exit 0
	fi
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
	modules_path="/lib/modules/${kernel}"
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

# NOTE: This does not work with busybox' modprobe
# That's why postmarketos-mkinitfs depends on kmod
get_modules_by_name()
{
	{
		echo "Scanning kernel module dependencies..."
		echo "NOTE: ** modprobe warnings below can be ignored ** if your device does not run the"
		echo "mainline kernel yet (most devices!) or if the related kernel options are enabled"
		echo "with 'y' instead of 'm' (module)."
	} >&2

	MODULES="dm_crypt ext4 usb_f_rndis \
		${deviceinfo_modules_initfs}"
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
BINARIES="/bin/busybox /bin/busybox-extras /usr/sbin/telnetd /sbin/kpartx"
BINARIES_EXTRA="
	$(find /usr/lib/directfb-* -name '*.so')
	/lib/libz.so.1
	/sbin/cryptsetup
	/sbin/dmsetup
	/sbin/e2fsck
	/usr/bin/charging-sdl
	/usr/bin/osk-sdl
	/usr/lib/libGL.so.1
	/usr/lib/libts*
	/usr/lib/ts/*
	/usr/sbin/parted
	/usr/sbin/resize2fs
	/usr/sbin/thd
"
get_binaries()
{
	for file in "/etc/postmarketos-mkinitfs/files"/*.files; do
		[ -f "$file" ] || continue
		while IFS= read -r line; do
			BINARIES="${BINARIES} ${line}"
		done < "$file"
	done
	lddtree -l $BINARIES | sort -u
}

# Collect non-binary files for osk-sdl and its dependencies
# This gets called as $(get_osk_config), so the exit code can be checked/handled.
get_osk_config()
{
	fontpath=$(awk '/^keyboard-font/{print $3}' /etc/osk.conf)
	if [ ! -f $fontpath ]; then
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
	tmp1=$(mktemp /tmp/mkinitfs.XXXXXX)
	get_binaries > "$tmp1"
	tmp2=$(mktemp /tmp/mkinitfs.XXXXXX)
	lddtree -l $BINARIES_EXTRA | sort -u > "$tmp2"
	ret=$(comm -13 "$tmp1" "$tmp2")
	rm "$tmp1" "$tmp2"
	echo "${ret}"
}

# Copy files to the destination specified
# FIXME: this is a performance bottleneck
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
	cd "$1"
	[ -z "$deviceinfo_initfs_compression" ] && deviceinfo_initfs_compression='gzip -1'
	find . -print0 \
		| cpio --quiet -o -H newc \
		| $deviceinfo_initfs_compression > "$2"
}

# Required command check with useful error message
# $1: command (e.g. "mkimage")
# $2: package (e.g. "uboot-tools")
# $3: related deviceinfo variable (e.g. "generate_bootimg")
require_package()
{
	[ "$(command -v "$1")" == "" ] || return
	echo "ERROR: 'deviceinfo_$3' is set, but the package '$2' was not"
	echo "installed! Please add '$2' to the depends= line of your device's"
	echo "APKBUILD. See also: <https://postmarketos.org/deviceinfo>"
	exit 1
}

# Legacy u-boot images
create_uboot_files()
{
	arch="arm"
	if [ "${deviceinfo_arch}" == "aarch64" ]; then
		arch="arm64"
	fi

	[ "${deviceinfo_generate_legacy_uboot_initfs}" == "true" ] || return
	require_package "mkimage" "uboot-tools" "generate_legacy_uboot_initfs"

	echo "==> initramfs: creating uInitrd"
	mkimage -A $arch -T ramdisk -C none -n uInitrd -d "$outfile" \
		"${outfile/initramfs-/uInitrd-}" || exit 1

	echo "==> kernel: creating uImage"
	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ "${deviceinfo_append_dtb}" == "true" ]; then
		kernelfile="${kernelfile}-dtb"
	fi

	if [ -z "$deviceinfo_legacy_uboot_load_address" ]; then
		deviceinfo_legacy_uboot_load_address="80008000"
	fi

	mkimage -A $arch -O linux -T kernel -C none -a "$deviceinfo_legacy_uboot_load_address" \
		-e "$deviceinfo_legacy_uboot_load_address" \
		-n postmarketos -d $kernelfile "${outfile/initramfs-/uImage-}" || exit 1
}

# Android devices
create_bootimg()
{
	[ "${deviceinfo_generate_bootimg}" == "true" ] || return
	require_package "mkbootimg-osm0sis" "mkbootimg" "generate_bootimg"

	echo "==> initramfs: creating boot.img"
	_base="${deviceinfo_flash_offset_base}"
	[ -z "$_base" ] && _base="0x10000000"

	if [ "${deviceinfo_bootimg_mtk_mkimage}" == "true" ]; then
		require_package "mtk-mkimage" "mtk-mkimage" "bootimg_mtk_mkimage"
		mv $outfile $outfile-orig
		mtk-mkimage ROOTFS $outfile-orig $outfile
	fi

	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ "${deviceinfo_append_dtb}" == "true" ]; then
		kernelfile="${kernelfile}-dtb"
	fi
	_second=""
	if [ "${deviceinfo_bootimg_dtb_second}" == "true" ]; then
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
	if [ "${deviceinfo_bootimg_qcdt}" == "true" ]; then
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
	mkbootimg-osm0sis \
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
		-o "${outfile/initramfs-/boot.img-}" || exit 1
	if [ "${deviceinfo_bootimg_blobpack}" == "true" ]; then
		echo "==> initramfs: creating blob"
		blobpack "${outfile/initramfs-/blob-}" LNX \
			"${outfile/initramfs-/boot.img-}" || exit 1
	fi
}

# Append the correct device tree to the linux image file or copy the dtb to the boot partition
append_or_copy_dtb()
{
	[ -n "${deviceinfo_dtb}" ] || return
	dtb="/usr/share/dtb/${deviceinfo_dtb}.dtb"
	kernel="${outfile/initramfs-/vmlinuz-}"
	echo "==> kernel: device-tree blob operations"
	if ! [ -e "$dtb" ]; then
		echo "ERROR: File not found: $dtb"
		exit 1
	fi
	if [ "${deviceinfo_append_dtb}" == "true" ]; then
		echo "==> kernel: appending device-tree ${deviceinfo_dtb}"
		cat "$kernel" "$dtb" > "${kernel}-dtb"
	else
		echo "==> kernel: copying dtb ${deviceinfo_dtb} to boot partition"
		cp "$dtb" "$(dirname ${outfile})"
	fi
}

# Create the initramfs-extra archive
# $1: outfile
generate_initramfs_extra()
{
	echo "==> initramfs: creating $1"

	osk_conf="$(get_osk_config)"
	if [ $? -eq 1 ]; then
		echo "ERROR: Font specified in /etc/osk.conf does not exist!"
		exit 1
	fi

	# Ensure cache folder exists
	mkinitfs_cache_dir="/var/cache/postmarketos-mkinitfs"
	mkdir -p "$mkinitfs_cache_dir"

	# Generate cache output filename (initfs_extra_cache) by hashing all input files
	initfs_extra_files=$(echo "$BINARIES_EXTRA$osk_conf" | xargs -0 -I{} sh -c 'ls $1 2>/dev/null' -- {} | sort -u)
	initfs_extra_files_hashes="$(md5sum $initfs_extra_files)"
	initfs_extra_hash="$(echo "$initfs_extra_files_hashes" | md5sum | awk '{ print $1 }')"
	initfs_extra_cache="$mkinitfs_cache_dir/$(basename $1)_${initfs_extra_hash}"

	if ! [ -e "$initfs_extra_cache" ]; then
		# If a cached file is missing, clear the whole cache and create it
		rm -f ${mkinitfs_cache_dir}/*

		# Set up initramfs-extra in temp folder
		tmpdir_extra=$(mktemp -d /tmp/mkinitfs.XXXXXX)
		mkdir -p "$tmpdir_extra"
		copy_files "$(get_binaries_extra)" "$tmpdir_extra"
		copy_files "$osk_conf" "$tmpdir_extra"
		create_cpio_image "$tmpdir_extra" "$initfs_extra_cache"
		rm -rf "$tmpdir_extra"
	fi

	cp "$initfs_extra_cache" "$1"
}

# initialize
source_deviceinfo
parse_commandline "$1" "$2" "$3"
check_hook_files
echo "==> initramfs: creating $outfile"
tmpdir=$(mktemp -d /tmp/mkinitfs.XXXXXX)

# set up initfs in temp folder
create_folders
copy_files "$(get_modules)" "$tmpdir"
copy_files "$(get_binaries)" "$tmpdir"
copy_files "/etc/deviceinfo" "$tmpdir"
copy_files "/etc/postmarketos-mkinitfs/hooks/*.sh" "$tmpdir"
cp /usr/share/postmarketos-splashes/*.ppm.gz "$tmpdir"
create_device_nodes
ln -s "/bin/busybox" "$tmpdir/bin/sh"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init.sh.in" \
	"$tmpdir/init"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init_functions.sh" \
	"$tmpdir/init_functions.sh"

# finish up
replace_init_variables
create_cpio_image "$tmpdir" "$outfile"
append_or_copy_dtb
create_uboot_files
create_bootimg

rm -rf "$tmpdir"

generate_initramfs_extra "$outfile_extra"

exit 0
