pkgname=postmarketos-android-recovery-installer
pkgver=0.1.7
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
sha512sums="924f961e1a488134d265f43724d2b06a908ac1522706dc3f7118f0dec16453aa0a928fef6d9a31a6a747910df665e64f25c94c47a9e3f1d57db19abb0fd8210d  build_zip.sh
6390fc1b1c7dc8e917bb675d2e59e479782ac7754e97c4781866360ff704afe2d04f173a0ac74e3129db45328fab4b6b77a8717ee2e17c6ff79febadaa8ea034  update-binary
f19c15fd99cc806d088ddf9c954111e48635f971ca500beeaa4893eb25d19fe0601210a57e9ab1a1dc7a6d79a3154765e696ee3329bbb1875b6d6df36a7b3fb3  pmos_chroot
d65b72ffb1140425bf96b1e3ef75a517bebbfa70e6bdc584dbd91c2cbefce63377c744b3b33f1967bad37cb368aa746e25d25b10eebf464399b262f62378b0f4  pmos_install
514881d7812197830869c73428acc88f8a94dd02184634406ffe47884cd21d7b02ecc7806dae39308f026b1dbfca9ceee714fdfdc2bebc3ebcdeed71865de2b2  pmos_install_functions
c6355b6d823dac883e1a352f59a9a2199e2934d78a73df72dc3c4fc14ef93765a15179203d4a8a2ca0d841b63cd4c25c4689b63c8cf4d4da2bcec1f8ff76bff5  pmos_setpw"
