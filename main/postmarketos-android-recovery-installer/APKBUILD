pkgname=postmarketos-android-recovery-installer
pkgver=0.0.1
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
sha512sums="9c7a90965aeb7f19ac166282066063510eeba6691ae695b2821e1a9e050463378c56492a27b3bfd4c8155380e6f24adc558dd0c98fc308ee7335b00c7b12fc0b  build_zip.sh
874d7505f9940d98a67fd8e5881ab0b93ae9fd0c46d7f4004468a2e9bbe4853f4bf6db64380c27684a66ebbd45ebe3399219b3910799de24003b8399ab2a4497  update-binary
5647a089c95d291d5662bbe6931a01f8591823d63b0226832897a046f351121c2c5d6ebfc83dcf9762ac50774920393fea37c05a92f2079e9688d6fe58711e49  pmos_install
dba3da4d2c18a480fda3bda233052f946bfd5a5f4fe05115341d4dc1466519584930e116719c5338ef4309a51dfea7d2e531ed133723f59c8d6d0c5a4f73a26b  pmos_install_functions
1969a467bc1e0f04ed445dd78db4eb1ad77b769a6e04c35211ad2c45cb8293243f864e499cdecf6016292d1accb26e6f62073b2afab023a20a79e0ea3dc15bd9  pmos_setpw"
