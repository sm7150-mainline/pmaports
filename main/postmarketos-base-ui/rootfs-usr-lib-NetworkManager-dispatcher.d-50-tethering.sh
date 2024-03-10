#!/bin/sh -e
# shellcheck disable=SC1091
# Handle USB tethering with unudhcpd and NetworkManager while also
# keeping SSH login over USB working when tethering is disabled.
#
# Copyright (c) 2023 Dylan Van Assche
# SPDX-License-Identifier: GPL-3.0-or-later

# Must match with the supplied connection profile,
# using UUID allows the user to change the connection name if they want to.
con_uuid="83bd1823-feca-4c2b-9205-4b83dc792e1f"

. /usr/share/misc/source_deviceinfo

usb_network_function="${deviceinfo_usb_network_function:-ncm.usb0}"
usb_network_function_fallback="rndis.usb0"
if [ -n "$(cat /sys/kernel/config/usb_gadget/g1/UDC)" ]; then
	interface="$(
		cat "/sys/kernel/config/usb_gadget/g1/functions/$usb_network_function/ifname" 2>/dev/null ||
		cat "/sys/kernel/config/usb_gadget/g1/functions/$usb_network_function_fallback/ifname" 2>/dev/null ||
		echo 'usb0'
	)"
else
	interface='eth0'
fi

[ -e /etc/unudhcpd.conf ] && . /etc/unudhcpd.conf
host_ip="${unudhcpd_host_ip:-172.16.42.1}"
client_ip="${unudhcpd_client_ip:-172.16.42.2}"

# Skip if iface does not match
if [ "$DEVICE_IFACE" != "$interface" ]; then
	exit 0
fi

# Trigger a disconnect/connect event on the client side to request a new DHCP lease.
reactivate_gadget() {
	# Mount configFS
	mkdir -p /config
	mount -t configfs none /config || true

	logger -t nm-tethering "configFS mounted"

	# Reactivate gadget
	udc=$(cat /config/usb_gadget/g1/UDC)
	echo "" > /config/usb_gadget/g1/UDC
	sleep 1
	echo "$udc" > /config/usb_gadget/g1/UDC

	logger -t nm-tethering "gadget reactivated"

	# Unmount configFS
	umount /config
	rm -rf /config

	logger -t nm-tethering "configFS unmounted"
}

# Default static IP for SSH acccess
# 1. Configure NetworkManager connection to use IP 172.16.42.1, same as initfs.
# 2. Disable IPv6 as unudhcpd only supplies IPv4 addresses.
# 3. Start unudhcpd to handle DHCP requests.
# 4. Reactivate the USB Ethernet gadget to force the clients to reactivate the interface.
disable_tethering() {
	# Configure static IP and bring up connection automatically
	nmcli connection modify "$con_uuid" ipv4.address "$host_ip/16"
	nmcli connection modify "$con_uuid" ipv4.method "manual"
	nmcli connection modify "$con_uuid" ipv6.method "link-local"
	nmcli connection modify "$con_uuid" connection.autoconnect "true"

	# Restart unudhpcd and configure it similar to initfs
	killall unudhpcd || true
	(unudhcpd -i "$interface" -s "$host_ip" -c "$client_ip") &
	logger -t nm-tethering "unudhcpd started"

	# Reactivate gadget to apply changes
	reactivate_gadget
	logger -t nm-tethering "USB tethering disabled"
}

# USB tethering
# 1. Enforce 172.16.42.1 as host IP even in tethering mode.
# 2. Stop unudhcpd as NetworkManager will spawn dnsmasq to handle DNS and DHCP requests.
# 3. Reactivate the USB Ethernet gadget to force the clients to reactivate the interface.
enable_tethering() {
	# Enforce the same IP range as when tethering is disabled, this will retrigger
	# the script as we have to reapply again, also bring up connection automatically.
	ip=$(nmcli connection show "$con_uuid" --active | grep ipv4.addresses | tr -s " " | cut -d " " -f2)
	if [ "$ip" != "$host_ip/16" ]; then
		logger -t nm-tethering "Enforcing $host_ip/16 as DHCP range"
		nmcli connection modify "$con_uuid" ipv4.address "$host_ip/16"
		nmcli connection modify "$con_uuid" connection.autoconnect "true"
		nmcli device reapply "$interface"
		return
	fi

	# Kill unudhcpd if needed
	killall unudhcpd || true
	logger -t nm-tethering "unudhcpd stopped"

	# Reactivate gadget to apply changes
	reactivate_gadget
	logger -t nm-tethering "USB tethering enabled"
}

# Handle dispatcher events for tethering
method=$(nmcli connection show "$con_uuid" --active | grep ipv4.method | tr -s " " | cut -d " " -f2)
case $NM_DISPATCHER_ACTION in
	# Always disable tethering on insert or removal for security
	"up"|"down")
		disable_tethering

		# The connection may have been configured before to tethering which
		# is not desired when iface comes up or is shut down as tethering must be
		# disabled. Enforce this by triggering a reapply after modifying the connection
		# which will cause NetworkManager to trigger the script again.
		# If the iface is already down since dispatcher scripts are executed async,
		# the command will fail which is fine to ignore
		if [ "$method" = "shared" ]; then
			logger -t nm-tethering "Enforcing tethering disabled on iface up/down"
			nmcli device reapply "$interface" || true
		fi
		;;
	# Enable tethering if the user explicitly enabled it
	"reapply")
		if [ "$method" = "shared" ]; then
			enable_tethering
		elif [ "$method" = "manual" ]; then
			disable_tethering
		fi
		;;
esac
