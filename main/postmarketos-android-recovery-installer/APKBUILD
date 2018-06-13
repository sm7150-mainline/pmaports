pkgname=postmarketos-android-recovery-installer
pkgver=0.1.9
pkgrel=0
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
2400d18734d08b3d2f5ec2fe4e802cdcacddea851644b47505eff1aac47302699c171b880bca55dd1704cc9cef9ac26082ac89cee802b6bf57ff8cf649373328  pmos_chroot
ef6377f6c062b9a86eb9dfb2aa2c0049fda20f24ec75865a682a50e4655710a18bd7a470deab527e1dd4c273f9ea6a003ec03fc5748d44b1c4fbfc91baa9e358  pmos_install
1b19d507a9142e537d052037a0c0768f064ad9131ac8019b234178dc15c0590dbc549ccf553b7a7d55e977df269d4dc0567b520c890738cb80184fc8235222aa  pmos_install_functions
c6355b6d823dac883e1a352f59a9a2199e2934d78a73df72dc3c4fc14ef93765a15179203d4a8a2ca0d841b63cd4c25c4689b63c8cf4d4da2bcec1f8ff76bff5  pmos_setpw"
