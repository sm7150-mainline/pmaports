#!/bin/sh -e
# Description: check all kernel configs with 'pmbootstrap kconfig check'
# Options: native
# Use 'native' because it requires running pmbootstrap.
# https://postmarketos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	wget "https://gitlab.com/postmarketOS/ci-common/-/raw/master/install_pmbootstrap.sh"
	sh ./install_pmbootstrap.sh
	exec su "${TESTUSER:-pmos}" -c "sh -e $0"
fi

# Wrap pmbootstrap to use this repository for --aports
pmaports="$(cd "$(dirname "$0")"/..; pwd -P)"
_pmbootstrap="$(command -v pmbootstrap)"
pmbootstrap() {
	"$_pmbootstrap" --aports="$pmaports" "$@"
}

set -x
pmbootstrap kconfig check
