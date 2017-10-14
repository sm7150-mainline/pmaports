pkgname=postmarketos-android-recovery-installer
pkgver=0.0.6
pkgrel=0
pkgdesc="TWRP compatible postmarketOS installer script"
url="https://github.com/postmarketOS"
# multipath-tools: kpartx
depends="busybox-extras lddtree cryptsetup multipath-tools device-mapper parted util-linux zip e2fsprogs tar"
source="build_zip.sh
	update-binary
	pmos_install
	pmos_install_functions
	pmos_setpw"
arch="noarch"
license="GPL3"

package() {
	install -Dm755 "$srcdir/build_zip.sh" \
		"$pkgdir/sbin/build-recovery-zip"
	mkdir -p "$pkgdir/var/lib/postmarketos-android-recovery-installer/META-INF/com/google/android/"
	install -Dm644 "$srcdir"/update-binary \
		"$pkgdir/var/lib/postmarketos-android-recovery-installer/META-INF/com/google/android/update-binary"
	mkdir "$pkgdir/var/lib/postmarketos-android-recovery-installer/bin/"
	for file in pmos_install pmos_install_functions pmos_setpw; do
		install -Dm755 "$srcdir/$file" \
			"$pkgdir/var/lib/postmarketos-android-recovery-installer/bin/$file"
	done
	mkdir "$pkgdir/var/lib/postmarketos-android-recovery-installer/lib/"
}
sha512sums="7f58f54c648f67cc7818de6a5c73f0c998101ddb06987c88d7612e406fed25e16fbae53f46ee81249eb1a7ebc1ea0e4ec43493d6b7bbcea43684d1b8d40649ef  build_zip.sh
156f889593d82d4b1c88f3873299fc054e70e78bf26af37af4dd7770ed31a0a581f2cf03cad9e11a60159f424d2d3869fd6cd28600ad305469ddf01eaff49f6c  update-binary
34f3ebc81c95c3f0583748cd14ca63d657946327a6bf999cb07448516123aac17f243d13db2101a44514f6eeb7e07b9def60b32c32650f3ecc0452e98e566d54  pmos_install
b4c669ab6dfe330a30c575f864cea916ac357ae96547c2296d1b5399669c6f49570c60554985d2939a1d3e3cb464e3229e2b4724eba1dd5d920dcec1b0f7f0e3  pmos_install_functions
27dd89aa8471349995a1cbbc1034ead662a0d1dd70ca5490f3191ceaaeb853331003c20ffddbbd95fe822135a85c1beb1e2a32bb33b10c2a4177b30347a40555  pmos_setpw"
