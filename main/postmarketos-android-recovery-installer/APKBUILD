pkgname=postmarketos-android-recovery-installer
pkgver=0.1.4
pkgrel=0
pkgdesc="TWRP compatible postmarketOS installer script"
url="https://github.com/postmarketOS"
# multipath-tools: kpartx
depends="busybox-extras lddtree cryptsetup multipath-tools device-mapper parted util-linux zip e2fsprogs tar"
source="build_zip.sh
	update-binary
	pmos_chroot
	pmos_install
	pmos_install_functions
	pmos_setpw"
arch="noarch"
license="GPL3"

package() {
	install -Dm755 "$srcdir/build_zip.sh" \
		"$pkgdir/sbin/build-recovery-zip"
	install -Dm644 "$srcdir"/update-binary \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/META-INF/com/google/android/update-binary"
	install -Dm755 "$srcdir"/pmos_chroot \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/pmos_chroot"
	for file in pmos_install pmos_install_functions pmos_setpw; do
		install -Dm755 "$srcdir/$file" \
			"$pkgdir/var/lib/postmarketos-android-recovery-installer/chroot/bin/$file"
	done
}
sha512sums="f02e67d26f4f977c5098ff6eee51b53ec962982c41b8b33c1a206c218c483bd20f782c06622cf8d724a9a1cdb5b9cc1b76d3bf32e562c9b558747ca3f3408ffd  build_zip.sh
6390fc1b1c7dc8e917bb675d2e59e479782ac7754e97c4781866360ff704afe2d04f173a0ac74e3129db45328fab4b6b77a8717ee2e17c6ff79febadaa8ea034  update-binary
f19c15fd99cc806d088ddf9c954111e48635f971ca500beeaa4893eb25d19fe0601210a57e9ab1a1dc7a6d79a3154765e696ee3329bbb1875b6d6df36a7b3fb3  pmos_chroot
b932668aea823a98b7f7f3811413b1116e6444166a57f664f9b28687288e3cd39c31f5b272a632f30165b06974721a1bc880cbf7024ba091e8739ef30fcc2c6c  pmos_install
36d8ca5ae092f8de0a9e2658581d3d1f83483b5076446aebaf5e1ab377e49615c31b81c00a23bc74d569de12a73977291c9a73e4f19b2faa694d981010c3eb35  pmos_install_functions
c6355b6d823dac883e1a352f59a9a2199e2934d78a73df72dc3c4fc14ef93765a15179203d4a8a2ca0d841b63cd4c25c4689b63c8cf4d4da2bcec1f8ff76bff5  pmos_setpw"
