#!/bin/sh -e
# Copyright 2022 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
# Description: lint with various python tests
# Options: native
# Use 'native' because it requires pmbootstrap.
# https://postmarktos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	wget "https://gitlab.com/postmarketOS/ci-common/-/raw/master/install_pmbootstrap.sh"
	sh ./install_pmbootstrap.sh pytest
	exec su "${TESTUSER:-pmos}" -c "sh -e $0"
fi

# Require pytest to be installed on the host system
if [ -z "$(command -v pytest)" ]; then
	echo "ERROR: pytest command not found, make sure it is in your PATH."
	exit 1
fi

# Wrap pmbootstrap to use this repository for --aports
pmaports="$(cd $(dirname $0)/..; pwd -P)"
_pmbootstrap="$(command -v pmbootstrap)"
pmbootstrap() {
	"$_pmbootstrap" --aports="$pmaports" "$@"
}

# Make sure that the work folder format is up to date, and that there are no
# mounts from aborted test cases (pmbootstrap#1595)
pmbootstrap work_migrate
pmbootstrap -q shutdown

# Make sure we have a valid device (pmbootstrap#1128)
device="$(pmbootstrap config device)"
deviceinfo="$pmaports/device/*/device-$device/deviceinfo"
if ! [ -e $deviceinfo ]; then
	echo "ERROR: Could not find deviceinfo file for selected device '$device'."
	echo "Expected path: $deviceinfo"
	echo "Maybe you have switched to a branch where your device does not exist?"
	echo "Use 'pmbootstrap config device qemu-amd64' to switch to a valid device."
	exit 1
fi

# Run testcases
pytest -vv -x --tb=native "$pmaports/.ci/testcases" "$@"
