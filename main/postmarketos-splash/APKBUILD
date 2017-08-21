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

sha512sums="cd3593579d357bb16fd9c6754e66eb8702e7d6199c5e9f7024735f410d5365ff3d1a7199b8075aa7b502785c2de0f9302f8d492d3e005688e4f93883d344c3ac  make-splash.py
82234147a5e907203edb8f8531aba63d96156b600b148a8d986b1978ce2641ebf875880f4075709e8b5e8f92948598319f5157473ddcc14cf00be004255e44bc  config.ini"
