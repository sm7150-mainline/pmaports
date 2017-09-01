#!/bin/sh

fbdev=/sys/class/graphics/fb0
echo "480,1708" > $fbdev/virtual_size
cat $fbdev/modes > $fbdev/mode
