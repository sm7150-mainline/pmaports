#!/bin/sh

# Copyright 2017 Attila Szollosi
#
# This file is part of postmarketos-android-recovery-installer.
#
# postmarketos-android-recovery-installer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# postmarketos-android-recovery-installer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with postmarketos-android-recovery-installer.  If not, see <http://www.gnu.org/licenses/>.

set -e

DEVICE="$1"

# Copy files to the destination specified
# $1: files
# $2: destination
copy_files()
{
	for file in $1; do
		filename=$(basename "$file")
		install -Dm755 "$file" "$2"/"$filename"
	done
}

check_whether_exists()
{
	if [ ! -e "$1" ]
	then
		echo "$1 not found"
		return 1
	fi
}

BINARIES="/bin/busybox /bin/umount /sbin/cryptsetup /sbin/findfs /sbin/kpartx /sbin/mkfs.ext2 /sbin/mkfs.ext4 \
	/usr/sbin/parted /usr/sbin/partprobe"
# shellcheck disable=SC2086
LIBRARIES=$(lddtree -l $BINARIES | awk '/lib/ {print}' | sort -u)
copy_files "$BINARIES" chroot/bin/
copy_files "$LIBRARIES" chroot/lib/
check_whether_exists rootfs.tar.gz
zip -0 -r "pmos-$DEVICE.zip" .
