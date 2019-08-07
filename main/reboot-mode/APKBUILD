# Contributor: Daniele Debernardi <drebrez@gmail.com>
# Maintainer: Daniele Debernardi <drebrez@gmail.com>
pkgname=reboot-mode
pkgver=0.2
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

sha512sums="a0cd4097d24fb6c66edce60558942d18ccf45925013013e5af5437471b1a855abe12857deb45b5f970b04e8b9dba99177b9080fff584fbd16262f0a7aabbf4b1  reboot-mode.c"
