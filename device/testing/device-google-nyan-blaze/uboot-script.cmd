if test ${devtype} = "usb" ; then
	setenv bootargs console=null;
else 
	setenv bootargs console=null pmos_boot=/dev/mmcblk${devnum}p2 pmos_root=/dev/mmcblk${devnum}p3;
fi;

echo Loading DTB
load ${devtype} ${devnum}:2 ${fdt_addr_r} tegra124-nyan-blaze.dtb

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
