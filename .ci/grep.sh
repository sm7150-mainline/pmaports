#!/bin/sh -e
# Description: check various bad patterns with grep
# https://postmarktos.org/pmb-ci

if [ "$(id -u)" = 0 ]; then
	set -x
	apk -q add grep
	exec su "${TESTUSER:-build}" -c "sh -e $0"
fi

# Find CHANGEMEs in APKBUILDs
if grep -qr '(CHANGEME!)' *; then
	echo "ERROR: Please replace '(CHANGEME!)' in the following files:"
	grep --color=always -r '(CHANGEME!)' *
	exit 1
fi
