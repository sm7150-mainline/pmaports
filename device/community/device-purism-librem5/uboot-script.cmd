setenv bootargs init=/init.sh rw console=ttymxc0,115200 cma=256M PMOS_NO_OUTPUT_REDIRECT PMOS_FORCE_PARTITION_RESIZE
setenv mmcdev 0
setenv mmcpart 1

printenv

# select the correct dtb based on device revision
dtb_file=imx8mq-librem5.dtb
if itest.s "x2" == "x$board_rev" ; then
        dtb_file=imx8mq-librem5-r2.dtb
elif itest.s "x3" == "x$board_rev" ; then
        dtb_file=imx8mq-librem5-r3.dtb
fi

echo Loading DTB
ext2load mmc ${mmcdev}:${mmcpart} ${fdt_addr_r} ${dtb_file}

echo Loading Initramfs
ext2load mmc ${mmcdev}:${mmcpart} ${ramdisk_addr_r} uInitrd-purism-librem5

echo Loading Kernel
ext2load mmc ${mmcdev}:${mmcpart} ${kernel_addr_r} vmlinuz-purism-librem5

echo Resizing FDT
fdt addr ${fdt_addr_r}
fdt resize

echo Booting kernel
booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
