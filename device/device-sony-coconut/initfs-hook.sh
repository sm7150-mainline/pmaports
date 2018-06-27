#!/bin/sh

# Fix "panning" (see https://wiki.postmarketos.org/wiki/Troubleshooting:display#Changing_the_panning)
echo 0 0 > /sys/class/graphics/fb0/pan
