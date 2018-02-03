# Contributor: drebrez <drebrez@gmail.com>
# Maintainer: drebrez <drebrez@gmail.com>
pkgname=fbdebug
pkgver=0.1
pkgrel=0
pkgdesc="Framebuffer debugging tool"
url="https://github.com/postmarketOS"
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

sha512sums="adaad7542ccac8d10eac5761933c24de654ae169ea1d64649a8b728b4ecac987c77ca4f77d64a43e260c0042b207482936102ba55d9c528331eabefc746f3bae  fbdebug.c"
