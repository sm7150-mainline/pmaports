pkgname=postmarketos-android-recovery-installer
pkgver=0.0.7
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
sha512sums="5934797c1aec8b3f8650dd1a149000c1227552f768b5417eafebf2772da6b34579f3c96d9441053d152500b2f68f29ba0dccbabf6fd0191c924daffd01be6f89  build_zip.sh
6e658b6924c31deb55561c256eea842824d2d21fc90e4b8227c0c910153d3cf16dca86eab6a3dcdaeb36d625c34c1153f4858e6813df5f909d2f3445b3a6c710  update-binary
bc340a1a83673c7a66da09e44dc40b20305e5ef52dea3c9d8151d3c07064b7b2016d4fe99869bb9d725a5a3aeb0bd570af3e26a91c7da6905cd9f281a99adb4d  pmos_install
fb9507a82d44c580af714488d18e7b59a1be0aa60292578e6571df7905c312caaaefd7d54eb6ce1a0b768616e356ece45b50c3e28acce86312d6d8e028bdf389  pmos_install_functions
27dd89aa8471349995a1cbbc1034ead662a0d1dd70ca5490f3191ceaaeb853331003c20ffddbbd95fe822135a85c1beb1e2a32bb33b10c2a4177b30347a40555  pmos_setpw"
