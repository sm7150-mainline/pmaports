#!/bin/sh

# set framebuffer resolution
echo 1 > /sys/class/graphics/fb0/state
echo 240,640 > /sys/class/graphics/fb0/virtual_size
echo 0,320 > /sys/class/graphics/fb0/pan

