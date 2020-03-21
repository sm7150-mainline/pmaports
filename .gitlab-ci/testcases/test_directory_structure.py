#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
import glob
import os

expected_directories = [
    "console",
    "cross",
    "device/testing",
    "firmware",
    "hybris",
    "kde",
    "maemo",
    "main",
    "modem",
    "temp",
]


# pmbootstrap allows placing APKBUILDs in arbitrarily nested directories.
# This test makes sure all of them are in one of the expected locations.
def test_directories():
    apkbuilds = set(glob.iglob("**/APKBUILD", recursive=True))
    expected = set(f for d in expected_directories for f in glob.iglob(d + "/*/APKBUILD"))
    assert apkbuilds == expected, "Found APKBUILD in unexpected directory. " \
        "Consider adding it to test_directory_structure.py!"


# Make sure files are either:
#  - in root directory (README.md)
#  - hidden (.gitlab-ci/, device/.shared-patches/)
#  - or belong to a package (below a directory with APKBUILD)
def test_files_belong_to_package():
    # Walk directories and set package_dir when we find an APKBUILD
    # This allows matching files in subdirectories to the package directory.
    package_dir = None
    for dirpath, dirs, files in os.walk("."):
        # Skip "hidden" directories
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        # Ignore files in root directory
        if dirpath == '.':
            continue

        # Switched to another directory?
        if package_dir and not dirpath.startswith(package_dir + os.sep):
            package_dir = None

        if 'APKBUILD' in files:
            assert not package_dir, f"Nested packages: {package_dir} and {dirpath} " \
                "both contain an APKBUILD"
            package_dir = dirpath

        assert not files or package_dir, "Found files that do not belong to any package: " \
            f"{dirpath}/{files}"
