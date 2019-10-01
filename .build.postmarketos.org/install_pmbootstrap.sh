#!/bin/sh -e
# Copyright 2019 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

# Config: pmbootstrap tag (or branch)

if [ "$1" != "" ]; then
	tag="$1"
else
	tag="master"
fi

# Get download URL and pmaports path
url="https://gitlab.com/postmarketOS/pmbootstrap/-/archive/$tag/pmbootstrap-$tag.tar.bz2"
pmaports="$(cd $(dirname $0)/..; pwd -P)"

# Set up binfmt_misc
echo "Setting-up binfmt_misc"
sudo mount -t binfmt_misc none /proc/sys/fs/binfmt_misc

# Download pmbootstrap (to /tmp/pmbootstrap)
echo "Downloading pmbootstrap ($tag): $url"
cd /tmp
wget -q -O "pmb.tar.bz2" "$url"
tar -xf "pmb.tar.bz2"
mv pmbootstrap-* pmbootstrap

# Install to $PATH and init
sudo ln -s /tmp/pmbootstrap/pmbootstrap.py /usr/bin/pmbootstrap
echo "Initializing pmbootstrap with aports at '$pmaports'"
yes '' | pmbootstrap -q --aports "$pmaports" init
