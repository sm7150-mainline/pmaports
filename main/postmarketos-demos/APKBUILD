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
sha512sums="804bbd4e939bd49a153919a728ee17cf69e98e5d679f106054edf298d775849f8efa4716814ee4b84eaa6bcc2c38d16c2362922978cdd214290dd4968ce645bc  main.c
83d8a95e9e1e95dffa8661e547444e83e72e572dcd0c637376f678bbd20a351c4b971a315311edefeb58a4cca14fd3e586fb581a262b2d217e25092459539b98  Makefile"
