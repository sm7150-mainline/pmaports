#!/bin/sh

# activate touchscreen
echo 1 > /sys/devices/soc.0/78b6000.i2c/i2c-2/2-0020/drv_irq
