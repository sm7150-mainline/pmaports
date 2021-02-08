#!/usr/bin/env python3
# Copyright 2021 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import glob
import pytest
import sys
import os

import add_pmbootstrap_to_import_path
import pmb.parse


@pytest.fixture
def args(request):
    # Initialize args
    pmaports = os.path.realpath(f"{os.path.dirname(__file__)}/../..")
    sys.argv = ["pmbootstrap",
                "--aports", pmaports,
                "--log", "$WORK/log_testsuite_pmaports.txt"
                "chroot"]
    args = pmb.parse.arguments()

    # Initialize logging
    pmb.helpers.logging.init(args)
    request.addfinalizer(args.logfd.close)
    return args


def test_aports_kernel(args):
    """
    Various tests performed on the /**/linux-* aports.
    """
    for path in glob.iglob(args.aports + "**/linux-*/APKBUILD", recursive=True):
        apkbuild = pmb.parse.apkbuild(args, path)

        if "pmb:cross-native" not in apkbuild["options"]:
            raise RuntimeError("\"pmb:cross-native\" missing in"
                               f" options= line: {path}")
