#!/bin/sh -e
# Copyright 2021 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

set -e
DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$DIR/.."

# Find CHANGEMEs in APKBUILDs
if grep -qr '(CHANGEME!)' *; then
	echo "ERROR: Please replace '(CHANGEME!)' in the following files:"
	grep --color=always -r '(CHANGEME!)' *
	exit 1
fi

# Shellcheck isn't in Alpine anymore, so just download the static binary in CI
# Related: https://gitlab.alpinelinux.org/alpine/aports/-/issues/10902
if [ "$DOWNLOAD_SHELLCHECK" = 1 ]; then
	pkgver="0.7.2"
	tmpdir="/tmp/shellcheck-$pkgver"
	url="https://github.com/koalaman/shellcheck/releases/download/v$pkgver/shellcheck-v$pkgver.linux.x86_64.tar.xz"
	mkdir -p "$tmpdir"
	if ! [ -e "$tmpdir"/rel.tar.xz ]; then
		echo "Downloading $url"
		wget -q -O "$tmpdir"/rel.tar.xz "$url"
	fi
	tar -C "$tmpdir" -xf "$tmpdir"/rel.tar.xz
	export PATH="$tmpdir/shellcheck-v$pkgver/:$PATH"
fi

# Shell: shellcheck
sh_files="
	./main/mdss-fb-init-hack/mdss-fb-init-hack.sh
	./main/postmarketos-base/rootfs-usr-lib-firmwareload.sh
	./main/postmarketos-installkernel/installkernel-pmos
	./main/postmarketos-mkinitfs/init.sh
	./main/postmarketos-mkinitfs/init_functions.sh
	./main/postmarketos-mkinitfs-hook-debug-shell/20-debug-shell.sh
	./main/postmarketos-update-kernel/update-kernel.sh
	./main/swclock-offset/swclock-offset-boot.sh
	./main/swclock-offset/swclock-offset-shutdown.sh
	./main/ttyescape/*.sh
	./main/ttyescape/*.post-install
	./main/msm-firmware-loader/*.sh
	./main/msm-firmware-loader/*.post-install

	$(find . -path './main/postmarketos-ui-*/*.sh')
	$(find . -path './main/postmarketos-ui-*/*.pre-install')
	$(find . -path './main/postmarketos-ui-*/*.post-install')
	$(find . -path './main/postmarketos-ui-*/*.pre-upgrade')
	$(find . -path './main/postmarketos-ui-*/*.post-upgrade')
	$(find . -path './main/postmarketos-ui-*/*.pre-deinstall')
	$(find . -path './main/postmarketos-ui-*/*.post-deinstall')

	$(find . -name '*.trigger')
	$(find . -path './main/devicepkg-dev/*.sh')
	$(find . -path './main/postmarketos-mvcfg/*.sh')

	$(find . -path '.ci/*.sh')
"
for file in $sh_files; do
	echo "Test with shellcheck: $file"
	cd "$DIR/../$(dirname "$file")"
	shellcheck -e SC1008 -x "$(basename "$file")"
done
