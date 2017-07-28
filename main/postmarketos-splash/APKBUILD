pkgname=postmarketos-splash
pkgver=1
pkgrel=2
pkgdesc="Splash screen for postmarketOS"
url="https://github.com/postmarketos"
arch="noarch"
license="mit"
depends="ttf-dejavu ttf-droid py3-pillow"
makedepends=""
install=""
subpackages=""
source="make-splash.py config.ini"

build() {
	return 0
}

package() {
	install -D -m755 "$srcdir"/make-splash.py \
                "$pkgdir"/usr/bin/pmos-make-splash
	install -D -m644 "$srcdir"/config.ini \
		"$pkgdir"/etc/postmarketos/splash.ini
}

sha512sums="5a89cdaeec572262ae48248a0c92721bd53e40ddf83167be3ede6fef656e540f6f3cf8eac3d17ae9755ab523a69f760732d05b0de436347ed91272ca732ac938  make-splash.py
82234147a5e907203edb8f8531aba63d96156b600b148a8d986b1978ce2641ebf875880f4075709e8b5e8f92948598319f5157473ddcc14cf00be004255e44bc  config.ini"
