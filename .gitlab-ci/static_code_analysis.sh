#!/bin/sh -e
# Copyright 2019 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

set -e
DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$DIR/.."

# Find CHANGEMEs in APKBUILDs
if grep -qr '(CHANGEME!)' device; then
	echo "ERROR: Please replace '(CHANGEME!)' in the following files:"
	grep --color=always -r '(CHANGEME!)' device
	exit 1
fi

# Shell: shellcheck
sh_files="
	./main/postmarketos-base/firmwareload.sh
	./main/postmarketos-mkinitfs/init.sh.in
	./main/postmarketos-mkinitfs/init_functions.sh
	./main/postmarketos-mkinitfs-hook-debug-shell/20-debug-shell.sh
	./main/postmarketos-update-kernel/update-kernel.sh
	./main/postmarketos-android-recovery-installer/build_zip.sh
	./main/postmarketos-android-recovery-installer/pmos_chroot
	./main/postmarketos-android-recovery-installer/pmos_install
	./main/postmarketos-android-recovery-installer/pmos_install_functions
	./main/postmarketos-android-recovery-installer/pmos_setpw
	./main/postmarketos-android-recovery-installer/update-binary
	./main/mdss-fb-init-hack/mdss-fb-init-hack.sh
	./main/postmarketos-ui-hildon/postmarketos-ui-hildon.post-install
	$(find . -path './main/postmarketos-ui-hildon/*.sh')
	$(find . -name '*.trigger')
	$(find . -path './main/devicepkg-dev/*.sh')

	$(find . -path '.gitlab-ci/*.sh')
"
for file in ${sh_files}; do
	echo "Test with shellcheck: $file"
	cd "$DIR/../$(dirname "$file")"
	shellcheck -e SC1008 -x "$(basename "$file")"
done

# Python: flake8
# E501: max line length
# F401: imported, but not used (false positive: add_pmbootstrap_to_import_path)
# E722: do not use bare except
cd "$DIR/.."

echo "Test with flake8: testcases"
# shellcheck disable=SC2086
flake8 --ignore E501,F401,E722,W504,W605 $(find . -path "./.gitlab-ci/testcases/*.py")

echo "Test with flake8: all other Python files"
# shellcheck disable=SC2086
flake8 --ignore E501,E722,W504,W605 $(find . -not -path './.gitlab-ci/testcases/*' -a -name '*.py')

# Done
echo "Success!"
