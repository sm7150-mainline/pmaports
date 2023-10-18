#!/bin/sh
# shellcheck disable=SC1091
. /init_functions.sh
. /usr/share/misc/source_deviceinfo

# See: https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt
_configfs=/config/usb_gadget

if ! [ -e "$_configfs" ]; then
	echo "/config/usb_gadget does not exist, can't setup configfs usb mass storage gadget"
	exit 1
fi

# Create storage function.
usb_mass_storage_function="mass_storage.0"
if [ ! -d $_configfs/g1/functions/"$usb_mass_storage_function" ]; then
	if ! mkdir $_configfs/g1/functions/"$usb_mass_storage_function"; then
		echo "Couldn't create $_configfs/g1/functions/$usb_mass_storage_function"
		exit 1
	fi
fi

lun="0"
storage_dev="$1"
if [ -z "${storage_dev}" ]; then
	#https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html#cleaning-up
	#First unlink the config
	if [ -e $_configfs/g1/configs/c.1/"$usb_mass_storage_function" ]; then
		echo "Disabling current usb storage device"
		rm $_configfs/g1/configs/c.1/"$usb_mass_storage_function"
	fi
	#Delete the function config
	if [ -d $_configfs/g1/functions/"$usb_mass_storage_function" ]; then
		rmdir $_configfs/g1/functions/"$usb_mass_storage_function"
	fi
elif [ -e "${storage_dev}" ]; then
	if [ ! -d $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun" ]; then
		if ! mkdir $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"; then
			echo "  Couldn't create $_configfs/g1/functions/$usb_mass_storage_function/lun.$lun"
			exit 1
		fi

		echo "0" > $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"/removable
		echo "0" > $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"/nofua
		echo "0" > $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"/cdrom
		echo "LUN $lun" > $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"/inquiry_string
	fi
	echo "Setting $storage_dev as current usb storage"
	echo "$storage_dev" > $_configfs/g1/functions/"$usb_mass_storage_function/lun.$lun"/file

	# Link the usb storage instance to the configuration
	if [ ! -e $_configfs/g1/configs/c.1/"$usb_mass_storage_function" ]; then
		if ! ln -s $_configfs/g1/functions/"$usb_mass_storage_function" $_configfs/g1/configs/c.1; then
			echo "Couldn't symlink $usb_mass_storage_function"
			exit 1
		fi
	fi
else
	echo "$storage_dev not found"
	exit 1
fi

#Reset UDC to apply changes
setup_usb_configfs_udc

