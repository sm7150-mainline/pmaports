pkgname=postmarketos-demos
pkgver=5
pkgrel=0
pkgdesc="Simple touch menu for a few demo programs"
url="https://github.com/postmarketOS"
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
		"$pkgdir"/usr/bin/postmarketos-demos || return 1
}
sha512sums="f9093f79a1ae189637269318d7001b619d35ad68b291b7979de2f619f74bdb4cc6779dd2f98962fa1ba17b65c0d5b84dac5cd99c35b9b24fae00e65ab68d664d  main.c
83d8a95e9e1e95dffa8661e547444e83e72e572dcd0c637376f678bbd20a351c4b971a315311edefeb58a4cca14fd3e586fb581a262b2d217e25092459539b98  Makefile"
