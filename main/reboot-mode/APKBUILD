# Contributor: Daniele Debernardi <drebrez@gmail.com>
# Maintainer: Daniele Debernardi <drebrez@gmail.com>
pkgname=reboot-mode
pkgver=0.1
pkgrel=0
pkgdesc="Reboot the device to a specific mode"
url="https://postmarketos.org"
arch="all"
license="GPL-3.0-or-later"
makedepends="musl-dev linux-headers"
source="reboot-mode.c"
options="!check"
builddir="$srcdir/"

build() {
	gcc reboot-mode.c -o reboot-mode.o -c
	gcc reboot-mode.o -o reboot-mode
}

package() {
	install -Dm755 "reboot-mode" \
		"${pkgdir}/usr/sbin/reboot-mode"
}

sha512sums="569b6b1cf595e208b8c5731ea8d4334cd5458cbc2a63d5756014f55f04dd89a4b67ec0d0d01d7a1cd935ae13d44e62e3ea6765f626736bc3dc2029b890c20070  reboot-mode.c"
