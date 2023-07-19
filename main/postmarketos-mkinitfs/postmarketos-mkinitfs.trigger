#!/bin/sh -e

# only invoke mkinitfs if the deviceinfo exists in the rootfs
{ [ -f /etc/deviceinfo ] || [ -f /usr/share/deviceinfo/deviceinfo ]; } && /usr/sbin/mkinitfs
exit 0
