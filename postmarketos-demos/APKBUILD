pkgname=postmarketos-demos
pkgver=4
pkgrel=3
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
sha512sums="7cb25e4d6a0224800703d0ee138edbf1b4ab71120190445d1fa57bec0835a9ab0b37fb343a4f6e01de3e3c7ffc2fc5c0c9bbcb15f9e867a9f9014ed682a10275  main.c
83d8a95e9e1e95dffa8661e547444e83e72e572dcd0c637376f678bbd20a351c4b971a315311edefeb58a4cca14fd3e586fb581a262b2d217e25092459539b98  Makefile"
