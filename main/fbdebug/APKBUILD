# Contributor: drebrez <drebrez@gmail.com>
# Maintainer: drebrez <drebrez@gmail.com>
pkgname=fbdebug
pkgver=0.3
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

sha512sums="c2b99024d4d3f1a47b5dcdff175b611d3c16175553076badafdaf9628ed85f95d955d09366a25d34a0f63a00c58bbdd063f6f531f60254b20420d47d7e3adb2f  fbdebug.c"
