pkgname=postmarketos-splash
pkgver=2
pkgrel=0
pkgdesc="Splash screen for postmarketOS"
url="https://gitlab.com/postmarketos"
arch="noarch"
license="mit"
depends="ttf-dejavu ttf-droid py3-pillow"
makedepends=""
install=""
subpackages=""
source="make-splash.py config.ini https://gitlab.com/postmarketOS/artwork/raw/master/logo/pmos.ttf"

package() {
	install -D -m755 "$srcdir"/make-splash.py \
                "$pkgdir"/usr/bin/pmos-make-splash
	install -D -m644 "$srcdir"/config.ini \
		"$pkgdir"/etc/postmarketos/splash.ini
	install -D -m644 "$srcdir"/pmos.ttf \
		"$pkgdir"/usr/share/fonts/ttf-pmos/pmos.ttf
}

sha512sums="580c96501137bbd606ee0a946ac057777a1f07e780d84e40bfb7909db09d2704d308373baea6e25fde50866918e169070c0842893732c5fd339cc1f0c329f85a  make-splash.py
cdde481bf7c68840515b839d974dd1dddfb37551a2939780e13dce11331f7d1964043de48f8902a30372e9fc9f042bd4ee133e2098694739c452a76b70e97111  config.ini
81e5df350bf7f435ab5480f7028fc3cabf5a947fa0dff1ed219f6d9ac18a1250f5114887a9f5f270cc699af48cd77f23d14a84578ac8d2d0f3a3e90ec3211c45  pmos.ttf"
