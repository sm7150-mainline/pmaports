pkgname=postmarketos-demos
pkgver=6
pkgrel=0
pkgdesc="Simple touch menu for a few demo programs"
url="https://postmarketos.org"
arch="all"
license="GPL3+"
depends="weston-xwayland dbus"
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
		"$pkgdir"/usr/bin/postmarketos-demos
}
sha512sums="48db2907ea609bcdafd321aa8659a387ad6325641e01fd83d91be5d320eb6202ab628b73d914658333396e7751e1e283aed413db7e91cce2d782993ef38a7e05  main.c
83d8a95e9e1e95dffa8661e547444e83e72e572dcd0c637376f678bbd20a351c4b971a315311edefeb58a4cca14fd3e586fb581a262b2d217e25092459539b98  Makefile"
