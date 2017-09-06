pkgname=postmarketos-demos
pkgver=4
pkgrel=4
pkgdesc="Simple touch menu for a few demo programs"
url="https://github.com/postmarketOS"
arch="all"
license="GPL3+"
depends="weston-xwayland"
makedepends="gtk+3.0-dev"
subpackages=""
source="main.c Makefile"
options="!check"

build() {
	cd "$srcdir"
	make
}

package() {
	install -D -m755 "$srcdir"/postmarketos-demos \
		"$pkgdir"/usr/bin/postmarketos-demos || return 1
}
sha512sums="ae51469e6105dfd07e1ffb2ab3b6e2261239ca80b6e897951e7223cc8dd8fcb7c98f06f2e3870203a2f840ce4b5d425b4943ae0091631bbf48ae283d3cf1f86a  main.c
83d8a95e9e1e95dffa8661e547444e83e72e572dcd0c637376f678bbd20a351c4b971a315311edefeb58a4cca14fd3e586fb581a262b2d217e25092459539b98  Makefile"
