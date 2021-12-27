led tolinoshine2hd:white:on on
setenv bootargs console=ttymxc0,115200

echo Loading kernel
load mmc 0:1 0x80800000 vmlinuz

echo Loading DTB
load mmc 0:1 0x83000000 imx6sl-tolino-shine2hd.dtb

echo Loading initrd
load mmc 0:1 0x85000000 uInitrd

echo Booting kernel
bootz 0x80800000 0x85000000 0x83000000
