#!/bin/sh -e
# Description: lint CI related python scripts/tests
# https://postmarketos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	apk -q add ruff
	exec su "${TESTUSER:-build}" -c "sh -e $0"
fi

set -x

# shellcheck disable=SC2046
ruff --ignore E501,F401,E722,W605 $(find .ci -name '*.py')
