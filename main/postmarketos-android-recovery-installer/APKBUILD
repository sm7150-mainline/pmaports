pkgname=postmarketos-android-recovery-installer
pkgver=0.1.10
pkgrel=1
pkgdesc="TWRP compatible postmarketOS installer script"
url="https://postmarketos.org"
# multipath-tools: kpartx
depends="busybox-extras lddtree cryptsetup multipath-tools device-mapper parted util-linux zip e2fsprogs tar"
source="build_zip.sh
	update-binary
	disable-warning.c
	pmos_chroot
	pmos_install
	pmos_install_functions
	pmos_setpw"
arch="all"
options="!check"
license="GPL3"

build() {
	gcc -static -o disable-warning disable-warning.c
}

package() {
	install -Dm755 "$srcdir/build_zip.sh" \
		"$pkgdir/sbin/build-recovery-zip"
	install -Dm644 "$srcdir"/update-binary \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/META-INF/com/google/android/update-binary"
	install -Dm755 "$srcdir"/pmos_chroot \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/pmos_chroot"
	install -Dm755 "$srcdir"/disable-warning \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/disable-warning"
	for file in pmos_install pmos_install_functions pmos_setpw; do
		install -Dm755 "$srcdir/$file" \
			"$pkgdir/var/lib/postmarketos-android-recovery-installer/chroot/bin/$file"
	done
}
sha512sums="cd3c4a4bb246d8e2480a9968d3519373ab55126a5b77e975ce53333ed39349194f1afb0dea472d62bdb0ffef1ac93bbadaf3de6362db47ef34c922a1e65c95db  build_zip.sh
bb152e86ce420761dd2dca660552131610bb8f39cb7e30c75689aacc7cccddce17a90c998097f1b63b3d68a20f9c2c4823d8d591de156dff827381fe436f3b9d  update-binary
38c21dc80aa2530fc06c2960c1318e07d068d403af02133f09ba227106a9b23fb77c3bed904e6135b048846f2733bd5d043235e5ab04598ed9c8fa45cbb15586  disable-warning.c
2400d18734d08b3d2f5ec2fe4e802cdcacddea851644b47505eff1aac47302699c171b880bca55dd1704cc9cef9ac26082ac89cee802b6bf57ff8cf649373328  pmos_chroot
ef6377f6c062b9a86eb9dfb2aa2c0049fda20f24ec75865a682a50e4655710a18bd7a470deab527e1dd4c273f9ea6a003ec03fc5748d44b1c4fbfc91baa9e358  pmos_install
1b19d507a9142e537d052037a0c0768f064ad9131ac8019b234178dc15c0590dbc549ccf553b7a7d55e977df269d4dc0567b520c890738cb80184fc8235222aa  pmos_install_functions
c6355b6d823dac883e1a352f59a9a2199e2934d78a73df72dc3c4fc14ef93765a15179203d4a8a2ca0d841b63cd4c25c4689b63c8cf4d4da2bcec1f8ff76bff5  pmos_setpw"
