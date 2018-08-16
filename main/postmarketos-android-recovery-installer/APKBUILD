pkgname=postmarketos-android-recovery-installer
pkgver=0.1.8
pkgrel=1
pkgdesc="TWRP compatible postmarketOS installer script"
url="https://postmarketos.org"
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
sha512sums="924f961e1a488134d265f43724d2b06a908ac1522706dc3f7118f0dec16453aa0a928fef6d9a31a6a747910df665e64f25c94c47a9e3f1d57db19abb0fd8210d  build_zip.sh
6390fc1b1c7dc8e917bb675d2e59e479782ac7754e97c4781866360ff704afe2d04f173a0ac74e3129db45328fab4b6b77a8717ee2e17c6ff79febadaa8ea034  update-binary
2260c5c7bf069a9fa57af5fe343aa8a9da1e258faf9be1900abce0c5768abbec178ac51d3fc48648e9f2fe3bd8d1f4e71f6d4beea07b524aeb94fd054a6def46  pmos_chroot
94d06a7a73f76eb737e65ca2828f3c59d9cc532f2d2ec200e1407cd8fc266be192e33a8baa923e460a4335c7f5fb5232675d2e2e98a7e1ed07a257c67a0a5c5d  pmos_install
4ba66b336372b23252673f0929ea4f706ec287b5a902c8cb392a9cafb832db445bb7aecc9a7fac34f855babba057c56e3b10c015a1d055a66f0bfd42fef5828e  pmos_install_functions
c6355b6d823dac883e1a352f59a9a2199e2934d78a73df72dc3c4fc14ef93765a15179203d4a8a2ca0d841b63cd4c25c4689b63c8cf4d4da2bcec1f8ff76bff5  pmos_setpw"
