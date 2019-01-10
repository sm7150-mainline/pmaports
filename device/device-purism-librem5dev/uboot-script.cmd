setenv bootargs init=/init.sh rw console=ttymxc0,115200 earlycon=ec_imx7q,0x30860000,115200 video=HDMI-A-1:1920x1080-32@60 usbcore.autosuspend=-1 PMOS_NO_OUTPUT_REDIRECT PMOS_FORCE_PARTITION_RESIZE
setenv mmcdev 0
setenv mmcpart 1

printenv
echo Loading DTB
ext2load mmc ${mmcdev}:${mmcpart} ${fdt_addr} dtb-purism-librem5dev.dtb

echo Loading Initramfs
ext2load mmc ${mmcdev}:${mmcpart} ${initrd_addr} uInitrd-purism-librem5dev

echo Loading Kernel
ext2load mmc ${mmcdev}:${mmcpart} ${loadaddr} vmlinuz-purism-librem5dev

echo Resizing FDT
fdt addr ${fdt_addr}
fdt resize

echo Booting kernel
booti ${loadaddr} ${initrd_addr} ${fdt_addr}


