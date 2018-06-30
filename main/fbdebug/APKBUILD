# Contributor: drebrez <drebrez@gmail.com>
# Maintainer: drebrez <drebrez@gmail.com>
pkgname=fbdebug
pkgver=0.2
pkgrel=0
pkgdesc="Framebuffer debugging tool"
url="https://postmarketos.org"
arch="all"
license="GPL2"
makedepends="linux-headers"
source="fbdebug.c"
options="!check"
builddir="$srcdir/"

build() {
	gcc fbdebug.c -o fbdebug.o -c
	gcc fbdebug.o -o fbdebug
}

package() {
	install -Dm755 "${builddir}/fbdebug" \
		"${pkgdir}/usr/sbin/fbdebug"
}

sha512sums="d6e581f1de822ecac3a392ecd1a555d559fa28315006a94dbe86be2589137584b558e20abc5ae912e4b00c9d8a35db5139eb514b2c95dd2b2299a3fcd47cda46  fbdebug.c"
