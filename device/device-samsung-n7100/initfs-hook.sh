#!/bin/sh

# set framebuffer resolution
cat /sys/class/graphics/fb0/modes > /sys/class/graphics/fb0/mode
