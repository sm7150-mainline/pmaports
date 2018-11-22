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

sha512sums="c75972faa180567fccabf63723693a3dfe6240f891eee9d580a1bfce2a8858cb746a4cc9704990f90abe94f3759ac47ca5203f1309e525d880a8663235a7e209  fbdebug.c"
