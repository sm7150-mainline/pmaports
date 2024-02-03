#!/bin/sh

macaddr=$(sed -n "s/^.*androidboot\.wifimacaddr=\(\([0-9A-Fa-f]\{2\}:\)\{5\}[0-9A-Fa-f]\{2\}\).*$/\1/p" < /proc/cmdline)

/sbin/ip link set wlan0 address "$macaddr"
