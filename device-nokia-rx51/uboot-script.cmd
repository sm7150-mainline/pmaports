setenv mmcnum 0
setenv mmcpart 1
setenv mmctype ext2
setenv setup_omap_atag 1
setenv bootargs init=/init.sh rw console=tty0 console=tty02 omapfb_vram=7M omapfb.mode=lcd:848x480-16 nokia-modem.pm=0
setenv mmckernfile /uImage-nokia-rx51
setenv mmcinitrdfile /uInitrd-nokia-rx51
setenv mmcscriptfile
echo Loading initramfs
run initrdload
echo Loading kernel
run kernload
echo Booting kernel
run kerninitrdboot
