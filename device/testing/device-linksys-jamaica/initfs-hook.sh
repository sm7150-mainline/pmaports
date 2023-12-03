#!/bin/sh

# Enable USB Power
echo 482 > /sys/class/gpio/export
echo "out" >/sys/class/gpio/gpio482/direction
echo 0 >  /sys/class/gpio/gpio482/value
# Wait 5 seconds to let the kernel detect the usb stick
sleep 5
