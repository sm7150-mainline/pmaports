#!/usr/bin/env python3
# Copyright 2021 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import glob
import pytest
import sys
import os

import add_pmbootstrap_to_import_path
import pmb.parse


def test_aports_kernel(args):
    """
    Various tests performed on the /**/linux-* aports.
    """

    for path in glob.iglob(f"{args.aports}/**/linux-*/APKBUILD", recursive=True):
        apkbuild = pmb.parse.apkbuild(path)
        aport_name = os.path.basename(os.path.dirname(path))

        if "pmb:cross-native" not in apkbuild["options"]:
            raise RuntimeError(f"{aport_name}: \"pmb:cross-native\" missing in"
                               " options= line")

        # cross-compilers should not be in makedepends
        for ccc in ["gcc-armv7", "gcc-armhf", "gcc-aarch64",
                    "gcc4-armv7", "gcc4-armhf", "gcc4-aarch64",
                    "gcc6-armv7", "gcc6-armhf", "gcc6-aarch64"]:
            if ccc in apkbuild["makedepends"]:
                raise RuntimeError(f"{aport_name}: Cross-compiler ({ccc}) should"
                                   " not be explicitly specified in makedepends!"
                                   " pmbootstrap installs cross-compiler"
                                   " automatically.")

        # check some options only for main and community devices
        for dir in ["main", "device/main", "device/community"]:
            if path.startswith(f"{args.aports}/{dir}"):
                if "pmb:kconfigcheck-community" not in apkbuild["options"]:
                    raise RuntimeError(f"{aport_name}: \"pmb:kconfigcheck-community\" missing in"
                                       " options= line, required for all community/main devices.")
