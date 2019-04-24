#!/bin/sh

# Keep reloading the touchscreen driver until the probe is successful

while ! [ -d /dev/input ] ;
do
	rmmod edt_ft5x06
	modprobe edt_ft5x06
	sleep 2
done
