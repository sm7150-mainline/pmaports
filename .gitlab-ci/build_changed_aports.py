#!/usr/bin/env python3
# Copyright 2019 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

# Same dir
import common


def check_build(packages, verify_only=False):
    # Initialize build environment with less logging
    common.run_pmbootstrap(["build_init"])

    if verify_only:
        common.run_pmbootstrap(["--details-to-stdout", "checksum",
                                "--verify"] + list(packages))
    else:
        common.run_pmbootstrap(["--details-to-stdout", "build", "--strict",
                                "--force"] + list(packages))


if __name__ == "__main__":
    # Get and print modified packages
    common.add_upstream_git_remote()
    packages = common.get_changed_packages()

    # Build changed packages
    common.get_changed_packages_sanity_check(len(packages))
    if len(packages) == 0:
        print("no aports changed in this branch")
    else:
        verify_only = common.commit_message_has_string("[ci:skip-build]")
        if verify_only:
            print("WARNING: not building changed packages ([ci:skip-build])!")
            print("verifying checksums: " + ", ".join(packages))
        else:
            print("building in strict mode: " + ", ".join(packages))
        check_build(packages, verify_only)
