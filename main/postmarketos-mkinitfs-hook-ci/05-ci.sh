#!/bin/sh
# shellcheck disable=SC1091
. ./init_functions.sh
. /usr/share/misc/source_deviceinfo

TEST=""

DID_FAIL=0

echo "==> Running postmarketos-mkinitfs-hook-ci"
echo "==> disabling dmesg on console"
dmesg -n 2

for f in /usr/libexec/pmos-tests-initramfs/*; do
	echo -e "\n==> Running test $f\n\n"
	$f
	if [ $? -ne 0 ]; then
		echo "==> FAIL: $f"
		DID_FAIL=1
	else
		echo "==> OK: $f"
	fi
done

dmesg -n 8

if [ $DID_FAIL -ne 0 ]; then
	echo "==> PMOS-CI-FAIL"
else
	echo "==> PMOS-CI-OK"
fi

# We're done, kill it
# CDBA will exit if it sees 20 '~' characters
# in a row, send a whole bunch just to be sure
# In the worst case it will timeout.
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
