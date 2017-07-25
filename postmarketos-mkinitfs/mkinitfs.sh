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
		echo "usage: $(basename $0) -o OUTFILE KERNELVERSION"
		exit 1
	fi

	outfile=$2
	kernel=$3
	modules_path="/lib/modules/${kernel}"

	if [ ! -d ${abi_path} ]; then
		echo "ERROR: Modules path not found: ${modules_path}"
		exit 1
	fi
}

create_folders()
{
	for dir in /bin /sbin /usr/bin /usr/sbin /proc /sys /dev /tmp /lib \
		/sysroot; do
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
				find $file -type f
			elif [ -e "$file" ]; then
				echo $file
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
	BINARIES="/bin/busybox /bin/busybox-extras /sbin/cryptsetup /usr/sbin/telnetd /sbin/kpartx"
	lddtree -l $BINARIES | sort -u
}

# Copy files to the same destination in the initramfs
# FIXME: this is a performance bottleneck
# $1: files
copy_files()
{
	for file in $1; do
		install -Dm755 $file $tmpdir$file
	done
}

create_device_nodes()
{
	mknod -m 666 $tmpdir/dev/null c 1 3
	mknod -m 644 $tmpdir/dev/random c 1 8
	mknod -m 644 $tmpdir/dev/urandom c 1 9
}

replace_init_variables()
{
	sed -i "s:@MODULES@:${deviceinfo_modules_initfs} ext4:g" $tmpdir/init
}

create_cpio_image()
{
	cd "$tmpdir"
	find . -print0 \
		| cpio --quiet -o -H newc \
		| gzip -1 > "$outfile"
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
		-o "${outfile/initramfs-/boot.img-}"
}

# Create splash screens
generate_splash_screens()
{
	width=${deviceinfo_screen_width:-720}
	height=${deviceinfo_screen_height:-1280}

	pmos-make-splash --text="On-screen keyboard is not implemented yet, plug in a USB cable and run on your PC:\ntelnet 172.16.42.1" \
		--config /etc/postmarketos/splash.ini $width $height "${tmpdir}/splash1.ppm"

	pmos-make-splash --text="Loading..." --center \
		--config /etc/postmarketos/splash.ini $width $height "${tmpdir}/splash2.ppm"

	gzip "${tmpdir}/splash1.ppm"
	gzip "${tmpdir}/splash2.ppm"
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
parse_commandline $1 $2 $3
echo "==> initramfs: creating $outfile"
tmpdir=$(mktemp -d /tmp/mkinitfs.XXXXXX)

# set up initfs in temp folder
create_folders
copy_files "$(get_modules)"
copy_files "$(get_binaries)"
copy_files "/etc/postmarketos-mkinitfs/hooks/*.sh"
create_device_nodes
ln -s "/bin/busybox" "$tmpdir/bin/sh"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init.sh.in" \
	"$tmpdir/init"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init_functions.sh" \
	"$tmpdir/init_functions.sh"

# finish up
generate_splash_screens
replace_init_variables
create_cpio_image
append_device_tree
create_uboot_files
create_bootimg

rm -rf "$tmpdir"
exit 0
