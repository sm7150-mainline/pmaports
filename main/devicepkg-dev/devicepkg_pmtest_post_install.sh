#!/bin/sh

console=$1
subpkgname=${subpkgname:-ERROR}

if [ "$subpkgname" = "ERROR" ]; then
	echo "ERROR: devicepkg_pmtest_post_install should only be called" >&2
	echo "from an APKBUILD subpackage function" >&2
fi

# Install a trigger so that mkinitfs will run when this package is installed
# shellcheck disable=SC2154
mkdir -p "$subpkgdir/usr/share/mkinitfs-triggers/"
touch "$subpkgdir/usr/share/mkinitfs-triggers/$subpkgname"

# Echo out the .post-install data for the calling package to pipe to their
# .post-install file
cat <<EOF
#!/bin/sh

echo -e "\n# PMOS CI: enable console logging" >> /etc/deviceinfo
echo 'deviceinfo_kernel_cmdline_append="console=$console PMOS_NO_OUTPUT_REDIRECT"' >> /etc/deviceinfo
EOF
