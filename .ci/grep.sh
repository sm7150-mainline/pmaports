#!/bin/sh -e
# Description: check various bad patterns with grep
# https://postmarketos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	apk -q add grep
	exec su "${TESTUSER:-build}" -c "sh -e $0"
fi

# Find CHANGEMEs in APKBUILDs
if grep -qr '(CHANGEME!)' *; then
	echo "ERROR: Please replace '(CHANGEME!)' in the following files:"
	grep --color=always -r '(CHANGEME!)' *
	exit 1
fi

# DTBs installed to /usr/share/db
if grep -qr 'INSTALL_DTBS_PATH="$pkgdir"/usr/share/dtb' device/; then
	echo 'ERROR: Please do not install dtbs to /usr/share/dtb!'
	echo 'ERROR: Unless you have a good reason not to, please put them in /boot/dtbs'
	echo 'ERROR: Files that need fixing:'
	grep --color=always -r 'INSTALL_DTBS_PATH="$pkgdir"/usr/share/dtb' device/
	exit 1
fi
