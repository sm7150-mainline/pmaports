#!/bin/sh -e
# Description: check various bad patterns with grep
# https://postmarketos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	apk -q add grep
	exec su "${TESTUSER:-build}" -c "sh -e $0"
fi

# Find CHANGEMEs in APKBUILDs
if grep -qr '(CHANGEME!)' -- *; then
	echo "ERROR: Please replace '(CHANGEME!)' in the following files:"
	grep --color=always -r '(CHANGEME!)' -- *
	exit 1
fi

# DTBs installed to /usr/share/db
# shellcheck disable=SC2016
if grep -qr 'INSTALL_DTBS_PATH="$pkgdir"/usr/share/dtb' device/; then
	echo 'ERROR: Please do not install dtbs to /usr/share/dtb!'
	echo 'ERROR: Unless you have a good reason not to, please put them in /boot/dtbs'
	echo 'ERROR: Files that need fixing:'
	# shellcheck disable=SC2016
	grep --color=always -r 'INSTALL_DTBS_PATH="$pkgdir"/usr/share/dtb' device/
	exit 1
fi


# Find old mkinitfs paths (pre mkinitfs 2.0)
if grep -qr '/etc/postmarketos-mkinitfs' -- *; then
	echo "ERROR: Please replace '/etc/postmarketos-mkinitfs' with '/usr/share/mkinitfs' in the following files:"
	grep --color=always -r '/etc/postmarketos-mkinitfs' -- *
	exit 1
fi
if grep -qr '/usr/share/postmarketos-mkinitfs' -- *; then
	echo "ERROR: Please replace '/usr/share/postmarketos-mkinitfs' with '/usr/share/mkinitfs' in the following files:"
	grep --color=always -r '/usr/share/postmarketos-mkinitfs' -- *
	exit 1
fi

# Direct sourcing of deviceinfo
if grep --exclude='source_deviceinfo' -qEr 'source /etc/deviceinfo|\. /etc/deviceinfo' -- *; then
	echo 'ERROR: Please source the source_deviceinfo script instead of sourcing deviceinfo directly!'
	grep --color=always --exclude='rootfs-usr-share-misc-source_deviceinfo' -Er 'source /etc/deviceinfo|\. /etc/deviceinfo' -- *
	exit 1
fi
