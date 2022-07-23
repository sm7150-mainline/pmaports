#!/bin/sh
# GPL-3.0-or-later

set -e

# Declare used deviceinfo variables to pass shellcheck
deviceinfo_cgpt_kpart=""

# shellcheck disable=SC1091
. /etc/deviceinfo

partition=$(findfs PARTLABEL=pmOS_kernel)

echo "Flashing $deviceinfo_cgpt_kpart to $partition"
dd if="$deviceinfo_cgpt_kpart" of="$partition"

echo "Done."
