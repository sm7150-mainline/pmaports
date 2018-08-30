#!/bin/sh -e
# Copyright 2018 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
# usage: install_pmbootstrap.sh [ADDITIONAL_PACKAGE, ...]

# Config: pmbootstrap tag (or branch)
tag="feature/split-aports"

# Get download URL and pmaports path
url="https://gitlab.com/postmarketOS/pmbootstrap/-/archive/$tag/pmbootstrap-$tag.tar.bz2"
pmaports="$(cd $(dirname $0)/..; pwd -P)"

# Set up depends and binfmt_misc
depends="coreutils openssl python3 sudo $@"
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
su pmos -c "yes '' | pmbootstrap -q --aports '$pmaports' init"
echo ""
