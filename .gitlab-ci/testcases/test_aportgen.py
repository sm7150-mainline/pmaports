#!/usr/bin/env python3
# Copyright 2018 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import filecmp
import pytest
import sys
import os

import add_pmbootstrap_to_import_path
import pmb.aportgen
import pmb.config
import pmb.helpers.logging
import pmb.parse


@pytest.fixture
def args(request):
    # Initialize args
    sys.argv = ["pmbootstrap",
                "--aports", os.path.dirname(__file__) + "/../..",
                "--log", "$WORK/log_testsuite_pmaports.txt"
                "chroot"]
    args = pmb.parse.arguments()

    # Initialize logging
    pmb.helpers.logging.init(args)
    request.addfinalizer(args.logfd.close)
    return args


def test_aportgen(args, tmpdir):
    # Fake aports folder in tmpdir
    aports_real = args.aports
    args.aports = str(tmpdir)
    pmb.helpers.run.user(args, ["mkdir", "-p", str(tmpdir) + "/cross"])

    # Create aportgen folder -> code path where it still exists
    pmb.helpers.run.user(args, ["mkdir", "-p", args.work + "/aportgen"])

    # Generate all valid packages (gcc twice -> different code path)
    pkgnames = ["binutils-armhf", "musl-armhf", "busybox-static-armhf",
                "gcc-armhf", "gcc-armhf"]
    for pkgname in pkgnames:
        pmb.aportgen.generate(args, pkgname)
        path_new = args.aports + "/cross/" + pkgname + "/APKBUILD"
        path_old = aports_real + "/cross/" + pkgname + "/APKBUILD"
        assert os.path.exists(path_new)
        assert filecmp.cmp(path_new, path_old, False)


def test_aportgen_invalid_generator(args):
    with pytest.raises(ValueError) as e:
        pmb.aportgen.generate(args, "pkgname-with-no-generator")
    assert "No generator available" in str(e.value)


def test_aportgen_get_upstream_aport(args, monkeypatch):

    # Fake pmb.parse.apkbuild()
    def fake_apkbuild(*args, **kwargs):
        return apkbuild
    monkeypatch.setattr(pmb.parse, "apkbuild", fake_apkbuild)

    # Fake pmb.parse.apkindex.package()
    def fake_package(*args, **kwargs):
        return package
    monkeypatch.setattr(pmb.parse.apkindex, "package", fake_package)

    # Equal version
    func = pmb.aportgen.core.get_upstream_aport
    upstream = "main/gcc"
    upstream_full = args.work + "/cache_git/aports_upstream/" + upstream
    apkbuild = {"pkgver": "2.0", "pkgrel": "0"}
    package = {"version": "2.0-r0"}
    assert func(args, upstream) == upstream_full

    # APKBUILD < binary
    apkbuild = {"pkgver": "1.0", "pkgrel": "0"}
    package = {"version": "2.0-r0"}
    with pytest.raises(RuntimeError) as e:
        func(args, upstream)
    assert str(e.value).startswith("You can update your local checkout with")

    # APKBUILD > binary
    apkbuild = {"pkgver": "3.0", "pkgrel": "0"}
    package = {"version": "2.0-r0"}
    with pytest.raises(RuntimeError) as e:
        func(args, upstream)
    assert str(e.value).startswith("You can force an update of your binary")
