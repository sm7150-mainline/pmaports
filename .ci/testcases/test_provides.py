#!/usr/bin/env python3
# Copyright 2023 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
import glob
import logging
import os
import pytest
import sys

import add_pmbootstrap_to_import_path
import pmb.parse
import pmb.parse._apkbuild


def apkbuild_check_provides(path, apkbuild, version, pkgname, subpkgname=None):
    """
    Verify that a package or subpackage is using provides correctly.

    :param path: to the APKBUILD for the error message
    :param apkbuild: either the full return of pmb.parse.apkbuild() or a
                     subpackage of it (apkbuild["subpackages"][$subpkgname])
    :param version: like 1.0.0-r3 so we can check against it
    :param pkgname: package name
    :param subpkgname: subpackage name, if we are looking at a subpackage
    :returns: list of error strings
    """
    name = pkgname
    if subpkgname:
        name = f"{pkgname}:{subpkgname}"

    logging.info(f"{name}: checking provides")
    ret = []

    if not apkbuild["provides"]:
        return ret

    for provide in apkbuild["provides"]:
        # Having provides entries without version is valid if the
        # provider_priorty is also set (pma#1766)
        if apkbuild["provider_priority"]:
            continue
        # Otherwise the version =$pkgver-r$pkgrel needs to be set. pmbootstrap
        # already replaces the variables, so we check against the inserted
        # values here.
        if not provide.endswith(f"={version}"):
            provide_no_ver = provide.split("=", 1)[0]

            error = f"error in {path}:\n"
            if subpkgname:
                error += f"in subpackage:\n  {subpkgname}\n"
            else:
                error += f"in package:\n  {pkgname}\n"
            error += f"broken provides entry:\n  {provide_no_ver}\n"
            error += "\n"
            error += "This provides entry needs to be changed to"
            error += f" '{provide_no_ver}=$pkgver-r$pkgrel'"
            error += " (do not replace the variables, without '').\n"
            error += "\n"
            error += "If you know what you are doing and didn't add the"
            error += " version on purpose, you also need to set a"
            error += " provider_priority (pma#1766).\n"
            error += "Reference:"
            error += " https://wiki.alpinelinux.org/wiki/APKBUILD_Reference#provides"
            ret += [error]
    return ret


def test_provides(args):
    errors = []
    for path in glob.iglob(f"{args.aports}/**/APKBUILD", recursive=True):
        apkbuild = pmb.parse.apkbuild(path)
        pkgname = apkbuild["pkgname"]
        version = f"{apkbuild['pkgver']}-r{apkbuild['pkgrel']}"
        path_rel = os.path.relpath(path, args.aports)
        errors += apkbuild_check_provides(path_rel, apkbuild, version, pkgname)

        for subpkg, subpkg_data in apkbuild["subpackages"].items():
            if not subpkg_data:
                # default packaging function like -doc
                continue
            errors += apkbuild_check_provides(path_rel, subpkg_data, version,
                                              pkgname, subpkg)

    if errors:
        for error in errors:
            logging.error(error)
        raise RuntimeError(f"test_provides failed with {len(errors)} errors")
