#!/bin/sh -e
# Copyright 2020 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
# usage: install_pmbootstrap.sh [ADDITIONAL_PACKAGE, ...]

# Config: pmbootstrap tag (or branch)
tag="master"

# Get download URL and pmaports path
url="https://gitlab.com/postmarketOS/pmbootstrap/-/archive/$tag/pmbootstrap-$tag.tar.bz2"
pmaports="$(cd $(dirname $0)/..; pwd -P)"

# Set up depends and binfmt_misc
depends="coreutils openssl python3 sudo git $@"
echo "Installing dependencies: $depends"
apk -q add $depends
mount -t binfmt_misc none /proc/sys/fs/binfmt_misc

# Create pmos user
echo "Creating pmos user"
adduser -D pmos
chown -R pmos:pmos .
echo 'pmos ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Download pmbootstrap (to /tmp/pmbootstrap)
echo "Downloading pmbootstrap ($tag): $url"
cd /tmp
wget -q -O "pmb.tar.bz2" "$url"
tar -xf "pmb.tar.bz2"
mv pmbootstrap-* pmbootstrap

# Install to $PATH and init
ln -s /tmp/pmbootstrap/pmbootstrap.py /usr/local/bin/pmbootstrap
echo "Initializing pmbootstrap"
if ! su pmos -c "yes '' | pmbootstrap -q --aports '$pmaports' --details-to-stdout init"; then
	echo "ERROR: pmbootstrap init failed!"
	echo
	echo "Most likely, this means that pmbootstrap requires a newer"
	echo "pmaports version. Please rebase on the official pmaports.git"
	echo "master branch and try again."
	echo
	echo "Let us know in the chat or issues if you have trouble with that"
	echo "and we will be happy to help. Sorry for the inconvenience."
	echo
	echo "(If that does not help, click on 'Browse' in the 'Job artifacts'"
	echo "next to this log output, and have a look at log.txt.)"
	exit 1
fi
echo ""
