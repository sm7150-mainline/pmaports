#!/bin/sh

# Framebuffer
echo 0,1709 > /sys/devices/platform/mtkfb.0/graphics/fb0/pan
echo 480,2592 > /sys/devices/platform/mtkfb.0/graphics/fb0/virtual_size

