#!/bin/sh -e
# Copyright 2022 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
# Description: check pkgver/pkgrel bumps, amount of changed pkgs etc
# Options: native
# Use 'native' because it requires git commit history.
# https://postmarketos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	# In .gitlab-ci.yml currently .ci/pytest.sh runs before this and
	# already downloads and runs install_pmbootstrap.sh.
	if ! [ -e install_pmbootstrap.sh ]; then
		wget "https://gitlab.com/postmarketOS/ci-common/-/raw/master/install_pmbootstrap.sh"
		sh ./install_pmbootstrap.sh
	fi
	exec su "${TESTUSER:-pmos}" -c "sh -e $0"
fi

.ci/lib/check_changed_aports_versions.py
