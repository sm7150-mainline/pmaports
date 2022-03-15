if test ${devnum} -eq 2 ; then
	echo "Booting from SD";
	setenv pmos_boot_dev 1;
else
	echo "Booting from eMMC";
	setenv pmos_boot_dev 0;
fi;

setenv bootargs console=null mem=3523M pmos_boot=/dev/mmcblk${pmos_boot_dev}p2 pmos_root=/dev/mmcblk${pmos_boot_dev}p3

echo Loading DTB
load mmc ${devnum}:2 ${fdt_addr_r} exynos5800-peach-pi.dtb

echo Loading Initramfs
load mmc ${devnum}:2 ${ramdisk_addr_r} initramfs
setenv ramdisk_size ${filesize}

echo Loading Kernel
load mmc ${devnum}:2 ${kernel_addr_r} vmlinuz

echo Resizing FDT
fdt addr ${fdt_addr_r}
fdt resize

echo Booting Kernel
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${ramdisk_size} ${fdt_addr_r}

