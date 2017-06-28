#!/bin/sh
IP=172.16.42.1
TELNET_PORT=23

. /init_functions.sh

log "info" "show_splash $partition"

usb_setup_android() {
	SYS=/sys/class/android_usb/android0
	[ -e "$SYS" ] || return
	printf "%s" "0"		> "$SYS/enable"
	printf "%s" "18D1"	> "$SYS/idVendor"
	printf "%s" "D001"	> "$SYS/idProduct"
	printf "%s"	"rndis"	> "$SYS/functions"
	printf "%s" "1"		> "$SYS/enable"
}

dhcpcd_start()
{
	# get usb interface
	INTERFACE=""
	ifconfig rndis0 "$IP" && INTERFACE=rndis0
	if [ -z $INTERFACE ]; then
		ifconfig usb0 "$IP" && INTERFACE=usb0
	fi

	# create /etc/udhcpd.conf
	{
		echo "start 172.16.42.2"
		echo "end 172.16.42.254"
		echo "lease_file /var/udhcpd.leases"
		echo "interface $INTERFACE"
		echo "option subnet 255.255.255.0"
	} > /etc/udhcpd.conf
	udhcpd
}

telnetd_start()
{
	mkdir -p /dev/pts
	mount -t devpts devpts /dev/pts
	{
		echo '#!/bin/sh'
		echo '. /init_functions.sh'
		echo 'unlock_root_partition'
		echo 'killall cryptsetup telnetd'
	} > /telnet_connect.sh
	chmod +x /telnet_connect.sh
	telnetd -b "${IP}:${TELNET_PORT}" -l /telnet_connect.sh
}

partition=$(find_root_partition)

usb_setup_android
dhcpcd_start

if $(cryptsetup isLuks "$partition"); then
	log "info" "password needed to decrypt $partition, launching telnetd"
	telnetd_start
fi

