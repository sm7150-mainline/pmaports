#!/bin/sh

# Parse arguments
builddir=$1
pkgdir=$2
_carch=$3
_flavor=$4

if [ -z "$builddir" ] || [ -z "$pkgdir" ] || [ -z "$_carch" ] ||
	[ -z "$_flavor" ]; then
	echo "ERROR: missing argument!"
	echo "Please call downstreamkernel_package() with \$builddir, \$pkgdir,"
	echo "\$_carch and \$_flavor as arguments."
	exit 1
fi

# kernel.release
install -D "$builddir/include/config/kernel.release" \
	"$pkgdir/usr/share/kernel/$_flavor/kernel.release"

# zImage (find the right one)
# shellcheck disable=SC2164
cd "$builddir/arch/$_carch/boot"
_target="$pkgdir/boot/vmlinuz-$_flavor"
for _zimg in zImage-dtb Image.gz-dtb Image.gz *zImage Image; do
	[ -e "$_zimg" ] || continue
	echo "zImage found: $_zimg"
	install -Dm644 "$_zimg" "$_target"
	break
done
if ! [ -e "$_target" ]; then
	echo "Could not find zImage in $PWD!"
	exit 1
fi
