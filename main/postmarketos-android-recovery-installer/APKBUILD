pkgname=postmarketos-android-recovery-installer
pkgver=0.1.1
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
7c396f4ae50f71d8c5ecf0528d1841639da75934dc8bd160311969e0d461dfc2f851eb6aa0373ec5cced11430ebc961f55a79863badb68d70fcad43725f9396b  update-binary
823e87cd6fcfb2954eda042522f189ffb36c739107b4ab4d82bd5707e097faab08375973c7d569336edeafdc177f5d35a9a051ab109794b6313548713ed3ac80  pmos_chroot
caafd0e6345e2082e4a2dc7169b1dedf11fd4423e72a2a2d33a6056cf2ecbed2ffa5c995491cbc0a62518623d3d2830d754c28cc4dc68db2c4a9224492409168  pmos_install
36d8ca5ae092f8de0a9e2658581d3d1f83483b5076446aebaf5e1ab377e49615c31b81c00a23bc74d569de12a73977291c9a73e4f19b2faa694d981010c3eb35  pmos_install_functions
558680cfeac4ab5e191cffa0f875e762b923fa281ba65cbe64da525710f82e6f7707cb9e346ee53fa50bb19afc567c331b005cd9c20d00ec3869819cadd992a4  pmos_setpw"
