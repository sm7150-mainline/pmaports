if test ${devtype} = "usb" ; then
	setenv bootargs console=tty1 PMOS_NO_OUTPUT_REDIRECT;
else 
	setenv bootargs console=tty1 PMOS_NO_OUTPUT_REDIRECT pmos_boot=/dev/mmcblk${devnum}p2 pmos_root=/dev/mmcblk${devnum}p3;
fi;

if test -e ${devtype} ${devnum}:2 tegra124-nyan-big.dtb; then
	echo "Selecting DTB for 1366x768 panel";
	setenv fdtfile tegra124-nyan-big.dtb;
else
	echo "Selecting DTB for 1920x1080 panel";
	setenv fdtfile tegra124-nyan-big-fhd.dtb;
fi;

echo Loading DTB
load ${devtype} ${devnum}:2 ${fdt_addr_r} ${fdtfile}

echo Loading Initramfs
load ${devtype} ${devnum}:2 ${ramdisk_addr_r} initramfs
setenv ramdisk_size ${filesize}

echo Loading Kernel
load ${devtype} ${devnum}:2 ${kernel_addr_r} vmlinuz

echo Resizing FDT
fdt addr ${fdt_addr_r}
fdt resize

echo Booting Kernel
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${ramdisk_size} ${fdt_addr_r}
