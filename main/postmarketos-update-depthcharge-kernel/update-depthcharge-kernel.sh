#!/bin/sh
# GPL-3.0-or-later

set -e

# Declare used deviceinfo variables to pass shellcheck
deviceinfo_cgpt_kpart=""

. /usr/share/misc/source_deviceinfo

# shellcheck disable=SC2013
for x in $(cat /proc/cmdline); do
	[ "$x" = "${x#kern_guid=}" ] && continue
	GUID="${x#kern_guid=}"
	partition=$(findfs PARTUUID="$GUID")
	echo "Flashing $deviceinfo_cgpt_kpart to $partition"
	dd if="$deviceinfo_cgpt_kpart" of="$partition"
done

echo "Done."
