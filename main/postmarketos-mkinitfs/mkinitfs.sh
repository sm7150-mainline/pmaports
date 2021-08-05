#!/bin/sh

outfile=""
outfile_extra=""
# shellcheck disable=SC1091
. /usr/share/postmarketos-mkinitfs/mkinitfs_functions.sh

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
ln -s "/bin/busybox" "$tmpdir/bin/sh"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init.sh.in" \
	"$tmpdir/init"
install -Dm755 "/usr/share/postmarketos-mkinitfs/init_functions.sh" \
	"$tmpdir/init_functions.sh"

# finish up
replace_init_variables
create_cpio_image "$tmpdir" "$outfile"
append_or_copy_dtb
add_mtk_header
create_uboot_files
create_bootimg
flash_updated_boot_parts

rm -rf "$tmpdir"

generate_initramfs_extra "$outfile_extra"

sync
exit 0
