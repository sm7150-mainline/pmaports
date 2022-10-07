#!/bin/sh -e

if grep -r 'INSTALL_DTBS_PATH="$pkgdir"/usr/share/dtb'; then
	echo 'Please do not install dtbs to /usr/share/dtb!'
	echo 'Unless you have a good reason not to, please put them in /boot/dtbs'
	exit 1
fi
