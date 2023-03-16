#!/usr/bin/env python3
# Copyright 2023 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import glob
import tempfile
import sys
import subprocess

# Same dir
import common

# pmbootstrap
import add_pmbootstrap_to_import_path  # noqa
import pmb.parse
import pmb.helpers.logging


def check_kconfig(args, pkgnames):
    last_failed = None
    for i in range(len(pkgnames)):
        pkgname = pkgnames[i]
        print(f"  ({i+1}/{len(pkgnames)}) {pkgname}")

        apkbuild_path = pmb.helpers.pmaports.find(args, pkgname)
        apkbuild = pmb.parse._apkbuild.apkbuild(f"{apkbuild_path}/APKBUILD")

        options = []

        for opt in apkbuild["options"]:
            if "pmb:kconfigcheck" in opt:
                options += [opt]

        if len(options):
            options.sort()
            print(f'options="{" ".join(options)}"')

        if "!pmb:kconfigcheck" in apkbuild["options"]:
            print("skipped (!pmb:kconfigcheck)")
            continue

        if not pmb.parse.kconfig.check(args, pkgname, details=True):
            last_failed = pkgname

    return last_failed


def show_error(last_failed):
    print("")
    print("Please adjust your kernel config. This is required for getting your"
          " patch merged.")
    print("")
    print("Edit your kernel config:")
    print(f"  pmbootstrap kconfig edit {last_failed}")
    print("")
    print("Test this kernel config again:")
    print(f"  pmbootstrap kconfig check {last_failed}")
    print("")
    print("Run this check again (on all kernels you modified):")
    print("  pmbootstrap ci kconfig")
    print("")


if __name__ == "__main__":
    common.add_upstream_git_remote()
    pkgnames = common.get_changed_kernels()
    print(f"Changed kernels: {pkgnames}")

    if len(pkgnames) == 0:
        print("No kernels changed in this branch")
        exit(0)

    # Initialize args (so we can use pmbootstrap's kconfig parsing)
    sys.argv = ["pmbootstrap", "kconfig", "check"]
    args = pmb.parse.arguments()
    pmb.helpers.logging.init(args)

    print("Running kconfig check on changed kernels...")
    last_failed = check_kconfig(args, pkgnames)

    if last_failed:
        show_error(last_failed)
        exit(1)
