#!/bin/sh
# shellcheck disable=SC1091
. /etc/deviceinfo
. ./init_functions.sh

# Device requires usb network initialization through configfs first
setup_usb_network_configfs
