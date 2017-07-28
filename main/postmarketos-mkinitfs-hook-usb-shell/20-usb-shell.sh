#!/bin/sh
. ./init_functions.sh
TELNET_PORT=24

setup_usb_network
start_udhcpd
telnetd -b "${IP}:${TELNET_PORT}" -l /bin/sh

echo "---"
echo "WARNING: usb shell is active on ${IP}:${TELNET_PORT}."
echo "This is a security hole! Only use it for debugging, and"
echo "uninstall the usb-shell hook afterwards!"
echo "---"
