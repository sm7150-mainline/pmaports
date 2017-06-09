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

for i in /usr/share/postmarketos-mkinitfs/splash*.ppm.gz; do
	install -Dm644 "$i" "$tmpdir"/"$(basename $i)"
done

# finish up
replace_init_variables
create_cpio_image
rm -rf "$tmpdir"
exit 0
