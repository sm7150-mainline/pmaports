#!/bin/sh

# enable touchscreen
echo 1 > /sys/devices/f9966000.i2c/i2c-1/1-004a/drv_irq
