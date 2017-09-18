#!/bin/sh

source_deviceinfo()
{
	if [ ! -e "/etc/deviceinfo" ]; then
		echo "ERROR: Missing /etc/deviceinfo!"
		exit 1
	fi
	. /etc/deviceinfo
	if [ -z "${deviceinfo_modules_initfs}" ]; then
		echo "WARNING: deviceinfo_modules_initfs is empty!"
	fi
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

		# kms.modules
		kernel/drivers/char/agp
		kernel/drivers/gpu
		kernel/drivers/i2c
		kernel/drivers/video
		kernel/arch/x86/video/fbdev.ko

		# mmc.modules
		kernel/drivers/mmc

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
	MODULES="drm_kms_helper drm dm_crypt ext4 \
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
get_binaries()
{
	BINARIES="/bin/busybox /bin/busybox-extras /usr/sbin/telnetd /sbin/kpartx"
	if [ "${deviceinfo_msm_refresher}" == "true" ]; then
		BINARIES="${BINARIES} /usr/sbin/msm-fb-refresher"
	fi
	lddtree -l $BINARIES | sort -u
}

get_binaries_extra()
{
	BINARIES_EXTRA="
		/sbin/cryptsetup
		/sbin/dmsetup
		/usr/sbin/parted
		/sbin/e2fsck
		/usr/sbin/resize2fs
	"
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
# $3: file mode bits (as in chmod), default: 755
copy_files()
{
	mode="${3:-755}"
	for file in $1; do
		[ -e "$file" ] || continue
		install -Dm$mode "$file" "$2$file"
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
	find . -print0 \
		| cpio --quiet -o -H newc \
		| gzip -1 > "$2"
}

# Legacy u-boot images
create_uboot_files()
{
	[ "${deviceinfo_generate_legacy_uboot_initfs}" == "true" ] || return
	echo "==> initramfs: creating uInitrd"
	mkimage -A arm -T ramdisk -C none -n uInitrd -d "$outfile" "${outfile/initramfs-/uInitrd-}"

	echo "==> kernel: creating uImage"
	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ -n "${deviceinfo_dtb}" ]; then
		kernelfile="${kernelfile}-dtb"
	fi
	mkimage -A arm -O linux -T kernel -C none -a 80008000 -e 80008000 -n postmarketos -d $kernelfile "${outfile/initramfs-/uImage-}"
}

# Android devices
create_bootimg()
{
	[ "${deviceinfo_generate_bootimg}" == "true" ] || return
	echo "==> initramfs: creating boot.img"
	_base="${deviceinfo_flash_offset_base}"
	[ -z "$_base" ] && _base="0x10000000"

	kernelfile="${outfile/initramfs-/vmlinuz-}"
	if [ -n "${deviceinfo_dtb}" ]; then
		kernelfile="${kernelfile}-dtb"
	fi
	mkbootimg \
		--kernel "${kernelfile}" \
		--ramdisk "$outfile" \
		--base "${_base}" \
		--second_offset "${deviceinfo_flash_offset_second}" \
		--cmdline "${deviceinfo_kernel_cmdline}" \
		--kernel_offset "${deviceinfo_flash_offset_kernel}" \
		--ramdisk_offset "${deviceinfo_flash_offset_ramdisk}" \
		--tags_offset "${deviceinfo_flash_offset_tags}" \
		--pagesize "${deviceinfo_flash_pagesize}" \
		${deviceinfo_bootimg_qcdt:+ --dt /boot/dt.img} \
		-o "${outfile/initramfs-/boot.img-}"
}

# Create splash screens
generate_splash_screens()
{
	width=${deviceinfo_screen_width:-720}
	height=${deviceinfo_screen_height:-1280}

	pmos-make-splash --text="On-screen keyboard is not implemented yet, plug in a USB cable and run on your PC:\ntelnet 172.16.42.1" \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-telnet.ppm"
	gzip "${tmpdir}/splash-telnet.ppm"

	pmos-make-splash --text="Loading..." --center \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-loading.ppm"
	gzip "${tmpdir}/splash-loading.ppm"

	pmos-make-splash --text="boot partition not found\nhttps://postmarketos.org/troubleshooting" --center \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-noboot.ppm"
	gzip "${tmpdir}/splash-noboot.ppm"

	pmos-make-splash --text="initramfs-extra not found\nhttps://postmarketos.org/troubleshooting" --center \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-noinitramfsextra.ppm"
	gzip "${tmpdir}/splash-noinitramfsextra.ppm"

	pmos-make-splash --text="system partition not found\nhttps://postmarketos.org/troubleshooting" --center \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-nosystem.ppm"
	gzip "${tmpdir}/splash-nosystem.ppm"

	pmos-make-splash --text="unable to mount root partition\nhttps://postmarketos.org/troubleshooting" --center \
		--config /etc/postmarketos/splash.ini "$width" "$height" "${tmpdir}/splash-mounterror.ppm"
	gzip "${tmpdir}/splash-mounterror.ppm"
}

# Append the correct device tree to the linux image file
append_device_tree()
{
	[ -n "${deviceinfo_dtb}" ] || return
	dtb="/usr/share/dtb/${deviceinfo_dtb}.dtb"
	kernel="${outfile/initramfs-/vmlinuz-}"
	echo "==> kernel: appending device-tree ${deviceinfo_dtb}"
	cat $kernel $dtb > "${kernel}-dtb"
}

# initialize
source_deviceinfo
parse_commandline "$1" "$2" "$3"
echo "==> initramfs: creating $outfile"
tmpdir=$(mktemp -d /tmp/mkinitfs.XXXXXX)

if [ "${deviceinfo_msm_refresher}" == "true" ] && ! [ -e /usr/sbin/msm-fb-refresher ]; then
	echo "ERROR: Please add msm-fb-refresher as dependency to your device package,"
	echo "or set msm_refresher to false in your deviceinfo!"
	exit 1
fi

# set up initfs in temp folder
create_folders
copy_files "$(get_modules)" "$tmpdir"
copy_files "$(get_binaries)" "$tmpdir"
copy_files "/etc/deviceinfo" "$tmpdir" "644"
copy_files "/etc/postmarketos-mkinitfs/hooks/*.sh" "$tmpdir"
create_device_nodes
ln -s "/bin/busybox" "$tmpdir/bin/sh"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init.sh.in" \
	"$tmpdir/init"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init_functions.sh" \
	"$tmpdir/init_functions.sh"

# finish up
generate_splash_screens
replace_init_variables
create_cpio_image "$tmpdir" "$outfile"
append_device_tree
create_uboot_files
create_bootimg

rm -rf "$tmpdir"

# initialize initramfs-extra
echo "==> initramfs: creating $outfile_extra"
tmpdir_extra=$(mktemp -d /tmp/mkinitfs.XXXXXX)

# set up initfs-extra in temp folder
mkdir -p "$tmpdir_extra"
copy_files "$(get_binaries_extra)" "$tmpdir_extra"

# finish up
create_cpio_image "$tmpdir_extra" "$outfile_extra"

rm -rf "$tmpdir_extra"

exit 0
