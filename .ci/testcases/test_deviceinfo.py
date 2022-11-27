#!/usr/bin/env python3
# Copyright 2021 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import glob
import os
import pytest
import re
import sys

import add_pmbootstrap_to_import_path
import pmb.parse


def deviceinfo_obsolete(info):
    """
    Test for obsolete options used in the deviceinfo file. They must still be
    defined in pmbootstrap's config/__init__.py.
    """
    obsolete_options = [
        "usb_rndis_function",
        "weston_pixman_type",
    ]
    for option in obsolete_options:
        if option in info and info[option]:
            raise RuntimeError(f"option {option} is obsolete, please rename"
                               " or remove it (see reasons for removal of at"
                               " https://postmarketos.org/deviceinfo)")


def test_deviceinfo(args):
    """
    Parse all deviceinfo files successfully and run checks on the parsed data.
    """
    # Iterate over all devices
    last_exception = None
    count = 0
    pattern = re.compile("^deviceinfo_[a-zA-Z0-9_]*=\".*\"$")

    for folder in glob.glob(args.aports + "/device/*/device-*"):
        device = folder[len(args.aports):].split("-", 1)[1]

        f = open(folder[len(args.aports):][1:] + "/deviceinfo")
        lines = f.read().split("\n")
        f.close()

        try:
            for line in lines:
                # Require space after # for comments
                if line.startswith("#") and not line.startswith("# "):
                    raise RuntimeError("Comment style: please change '#' to"
                                       f" '# ': {line}")

                # Skip empty lines and comments
                if not line or line.startswith("# "):
                    continue

                # Variable can not be empty
                if '=""' in line:
                    raise RuntimeError("Please remove the empty variable: " + line)

                # Check line against regex (can't use multiple lines etc.)
                if not pattern.match(line) or line.endswith("\\\""):
                    raise RuntimeError("Line looks invalid, maybe missing"
                                       " quotes/multi-line string/comment next"
                                       f" to line instead of above? {line}")

            # Successful deviceinfo parsing / obsolete options
            info = pmb.parse.deviceinfo(args, device)
            deviceinfo_obsolete(info)

            # deviceinfo_name must start with manufacturer
            name = info["name"]
            manufacturer = info["manufacturer"]
            if not name.startswith(manufacturer) and \
                    not name.startswith("Google"):
                raise RuntimeError("Please add the manufacturer in front of"
                                   " the deviceinfo_name, e.g.: '" +
                                   manufacturer + " " + name + "'")

        # Don't abort on first error
        except Exception as e:
            last_exception = e
            count += 1
            print(device + ": " + str(e))

    # Raise the last exception
    if last_exception:
        print("deviceinfo error count: " + str(count))
        raise last_exception
