#!/bin/sh
echo 0xFF000000 > /sys/class/leds/as3668/color
echo 50 > /sys/class/leds/as3668/brightness
