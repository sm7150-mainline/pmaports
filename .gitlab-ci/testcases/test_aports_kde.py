#!/usr/bin/env python3
# Copyright 2018 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import glob
import logging
import os
import pytest
import sys

import add_pmbootstrap_to_import_path
import pmb.config
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


def get_categorized_kde_packages(args):
    """
    Parse all aports in the kde folder, and categorize them.

    :returns: {"plasma": {"kwin": "5.13.3", ...},
               "kde": {"kcrash": "5.48.0", ...},
               "other": {"konsole": "1234", ...}}
    """
    ret = {"plasma": {}, "kde": {}, "other": {}}

    for path in glob.glob(args.aports + "/kde/*/APKBUILD"):
        # Parse APKBUILD
        apkbuild = pmb.parse.apkbuild(args, path)
        url = apkbuild["url"]
        pkgname = apkbuild["pkgname"]
        pkgver = apkbuild["pkgver"]

        # Categorize by URL
        category = "other"
        if "https://www.kde.org/workspaces/plasmadesktop" in url:
            category = "plasma"
        elif "https://community.kde.org/Frameworks" in url:
            category = "kde"

        # Save result
        ret[category][pkgname] = pkgver
    return ret


def check_categories(categories):
    """
    Make sure that all packages in one framework (kde, plasma) have the same
    package version (and that there is at least one package in each category).

    :param categories: see return of get_categorized_kde_packages()
    :returns: True when the check passed, False otherwise
    """
    ret = True
    for category, packages in categories.items():
        reference = None
        for pkgname, pkgver in packages.items():

            # Use the first package as reference and print a summary
            if not reference:
                logging.info("---")
                logging.info("KDE package category: " + category)
                logging.info("Packages (" + str(len(packages)) + "): " +
                             ", ".join(sorted(packages.keys())))
                reference = {"pkgname": pkgname, "pkgver": pkgver}

                # Category "other": done after printing the summary, no need to
                # compare the package versions
                if category == "other":
                    break

                # Print the reference and skip checking it against itself
                logging.info("Reference pkgver: " + pkgver + " (from '" +
                             pkgname + "')")
                continue

            # Check version against reference
            if pkgver != reference["pkgver"]:
                logging.info("ERROR: " + pkgname + " has version " + pkgver)
                ret = False

        # Each category must at least have one package
        if not reference:
            logging.info("ERROR: could not find any packages in category: " +
                         category)
            ret = False
    return ret


def test_kde_versions(args):
    """
    Make sure that KDE packages of the same framework have the same version.
    """
    categories = get_categorized_kde_packages(args)
    if not check_categories(categories):
        raise RuntimeError("KDE version check failed!")
