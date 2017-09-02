pkgname=postmarketos-splash
pkgver=1
pkgrel=3
pkgdesc="Splash screen for postmarketOS"
url="https://github.com/postmarketos"
arch="noarch"
license="mit"
depends="ttf-dejavu ttf-droid py3-pillow"
makedepends=""
install=""
subpackages=""
source="make-splash.py config.ini https://github.com/postmarketOS/artwork/raw/master/logo/pmos.ttf"

build() {
	return 0
}

package() {
	install -D -m755 "$srcdir"/make-splash.py \
                "$pkgdir"/usr/bin/pmos-make-splash
	install -D -m644 "$srcdir"/config.ini \
		"$pkgdir"/etc/postmarketos/splash.ini
	install -D -m644 "$srcdir"/pmos.ttf \
		"$pkgdir"/usr/share/fonts/ttf-pmos/pmos.ttf
}

sha512sums="1bc981e21d2186dcc8bbc1cea1d8893aa4be5bace763e4df7e91c6949babcc612f12ff4426d0e592f810c7d3448dba3d603ebfce5eb2eb0fd76f6cca8e571139  make-splash.py
cdde481bf7c68840515b839d974dd1dddfb37551a2939780e13dce11331f7d1964043de48f8902a30372e9fc9f042bd4ee133e2098694739c452a76b70e97111  config.ini
81e5df350bf7f435ab5480f7028fc3cabf5a947fa0dff1ed219f6d9ac18a1250f5114887a9f5f270cc699af48cd77f23d14a84578ac8d2d0f3a3e90ec3211c45  pmos.ttf"
