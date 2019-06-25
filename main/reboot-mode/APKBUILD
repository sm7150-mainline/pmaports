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

sha512sums="37d282608f30b1b8fa4f7501a8afcaa81902c9dfaee0c4c92ab05028e3a99a69c601dc7fce6ab06582db044b6fd0f5bffabe9d6064af9e670266978d66fe2515  reboot-mode.c"
