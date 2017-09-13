setenv mmcnum 0
setenv mmcpart 1
setenv mmctype ext2
setenv setup_omap_atag 1
setenv bootargs init=/init.sh rw console=tty0 console=tty02
setenv mmckernfile /uImage-postmarketos
setenv mmcinitrdfile /uInitrd-postmarketos
setenv mmcscriptfile
echo Loading initramfs
run initrdload
echo Loading kernel
run kernload
echo Booting kernel
run kerninitrdboot
