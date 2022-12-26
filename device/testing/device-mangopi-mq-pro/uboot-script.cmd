
setenv bootdev 0

printenv

echo Loading DTB
load mmc ${mmc_bootdev}:1 ${fdt_addr_r} /sun20i-d1-mangopi-mq-pro.dtb

echo Loading Grub
load mmc ${mmc_bootdev}:1 ${kernel_addr_r} /EFI/BOOT/BOOTRISCV64.EFI

echo Resizing FDT
fdt addr ${fdt_addr_r}
fdt resize


echo Booting Grub
bootefi ${kernel_addr_r} ${fdt_addr_r}

