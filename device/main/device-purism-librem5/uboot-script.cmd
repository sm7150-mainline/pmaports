# Uses the following env. vars:
#  devtype              e.g. mmc/scsi etc
#  devnum               The device number of the given type
#  bootpart             The partition containing the boot files
#  board_rev            Librem 5 board revision


# Default to devtype=mmc, devnum=0, bootpart=1 if they are unset in the
# environment. For supporting older u-boot where these may not be configured.
if itest.s "x" == "x$devtype" ; then
        devtype="mmc"
fi
if itest.s "x" == "x$devnum" ; then
        devnum=0
fi
if itest.s "x" == "x$bootpart" ; then
        bootpart=1
fi

setenv bootargs init=/init.sh rw console=ttymxc0,115200 cma=256M PMOS_NO_OUTPUT_REDIRECT PMOS_FORCE_PARTITION_RESIZE

# select the correct dtb based on device revision
# default to "-r2" if board_rev isn't set, since it'll boot on any librem5
# revision
dtb_file=imx8mq-librem5-r2.dtb
if itest.s "x3" == "x$board_rev" ; then
        dtb_file=imx8mq-librem5-r3.dtb
elif itest.s "x4" == "x$board_rev" ; then
        dtb_file=imx8mq-librem5-r4.dtb
fi

echo Loading DTB
ext2load $devtype ${devnum}:${bootpart} ${fdt_addr_r} ${dtb_file}

echo Loading Initramfs
ext2load $devtype ${devnum}:${bootpart} ${ramdisk_addr_r} initramfs

echo Loading Kernel
ext2load $devtype ${devnum}:${bootpart} ${kernel_addr_r} vmlinuz

echo Resizing FDT
fdt addr ${fdt_addr_r}
fdt resize

# For debug
printenv

echo Booting kernel
booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
