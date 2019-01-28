#!/bin/sh
srcdir=$1
builddir=$2
_config=$3
_carch=$4
HOSTCC=$5

if [ -z "$srcdir" ] || [ -z "$builddir" ] || [ -z "$_config" ] ||
	[ -z "$_carch" ] || [ -z "$HOSTCC" ]; then
	echo "ERROR: missing argument!"
	echo "Please call downstreamkernel_prepare() with \$srcdir, \$builddir,"
	echo "\$_config, \$_carch and \$HOSTCC as arguments."
	exit 1
fi

# support newer GCC versions
cp -v "/usr/share/devicepkg-dev/compiler-gcc.h" "$builddir/include/linux/"

# Remove -Werror from all makefiles
makefiles="$(find "$builddir" -type f -name Makefile)
	$(find "$builddir" -type f -name Kbuild)"
for i in $makefiles; do
	sed -i 's/-Werror-/-W/g' "$i"
        sed -i 's/-Werror=/-W/g' "$i"
	sed -i 's/-Werror//g' "$i"
done

# Prepare kernel config ('yes ""' for kernels lacking olddefconfig)
cp "$srcdir/$_config" "$builddir"/.config
yes "" | make -C "$builddir" ARCH="$_carch" HOSTCC="$HOSTCC" oldconfig
