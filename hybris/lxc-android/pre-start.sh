#!/bin/sh
lxc_config_path="$(dirname $LXC_CONFIG_FILE)"

# Allow pre-start.sh to be provided by device package, otherwise use the default one
if [ -f "$lxc_config_path/pre-start.custom.sh" ]; then
	exec $lxc_config_path/pre-start.custom.sh
else
	exec $lxc_config_path/pre-start.default.sh
fi
