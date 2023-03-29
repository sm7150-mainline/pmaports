if fatload mmc 0 0x1000000 u-boot.bin; then go 0x1000000; fi;
if fatload usb 0 0x1000000 u-boot.bin; then go 0x1000000; fi;
if ext4load mmc 0 0x1000000 u-boot.bin; then go 0x1000000; fi;
if ext4load usb 0 0x1000000 u-boot.bin; then go 0x1000000; fi;
