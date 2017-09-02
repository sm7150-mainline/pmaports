pkgname=postmarketos-android-recovery-installer
pkgver=0.0.2
pkgrel=1
pkgdesc="TWRP compatible postmarketOS installer script"
url="https://github.com/postmarketOS"
# multipath-tools: kpartx
depends="busybox-extras lddtree cryptsetup multipath-tools device-mapper parted zip"
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
sha512sums="4e4f56c84b404c53c3835304e8f7b651d6dbf19a653358daa6be1cc47e23360cb1dabb1331c13dd288fabb8eabaf8a01d094f054c334a156ca79f03948c9a17f  build_zip.sh
22083b3c776ae2e3e098dc8d9c4e085e7aae543aef20b42732c6750608e22c69211e199b946d55581403b71eb78e6508f618128122058a59466ad8a632e46ed8  update-binary
446d0d00322c92a5af7e5be340e9f185ef41eaa9cf6df4f5b29f3437dfcf45e0bc5e845c1c5a864694f8e89efd1a30e5e615b7ccfff1b7a0571dfb6f1f5cf3e5  pmos_install
152bcf1375cff515205af2427e537ae8536537f3ce7cbcbe7b848496be5af45baa149fe676c2d4979dcef017b843280752d35587b1e81905fa6daa2444e037c8  pmos_install_functions
27dd89aa8471349995a1cbbc1034ead662a0d1dd70ca5490f3191ceaaeb853331003c20ffddbbd95fe822135a85c1beb1e2a32bb33b10c2a4177b30347a40555  pmos_setpw"
