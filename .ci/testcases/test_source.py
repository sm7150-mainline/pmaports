#!/usr/bin/env python3
# Copyright 2022 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later
# Various checks on source= in the APKBUILDs

import glob
import pytest
import sys
import os

import add_pmbootstrap_to_import_path
import pmb.parse
import pmb.parse._apkbuild
import pmb.parse.apkindex
import pmb.helpers.repo


def parse_source_from_checksums(args, apkbuild_path):
    """
    Read the APKBUILD file and parse source files from the checksums at the
    bottom. This has always the same format, even if $source is built with hard
    to parse shell code (like in postmarketos-base).

    :param apkbuild_path: full path to the APKBUILD
    :returns: dict of parsed "source" filenames and checksums, e.g.:
              {"first.patch": "b4dc4f3…",
               "second.patch": "b4dc4f3…"}
    """
    start = 'sha512sums="'
    in_block = False
    ret = {}

    with open(apkbuild_path, encoding="utf-8") as handle:
        for line in handle.readlines():
            # Find start
            if not in_block:
                if line.startswith(start):
                    in_block = True
                else:
                    continue

            # sha512sums may have lines without checksums:
            # https://gitlab.alpinelinux.org/alpine/abuild/-/merge_requests/73
            if "  " not in line:
                continue

            try:
                checksum, filename = line.rstrip().split("  ", 2)
            except ValueError:
                raise ValueError("Failed to parse checksums. Try to delete the"
                                 " checksums and generate them again with"
                                 f" 'pmbootstrap checksum': {apkbuild_path}")

            # Cut off 'sha512sums="' if the first checksum is in that line
            if checksum.startswith(start):
                checksum = checksum[len(start):]

            # Find end
            if filename.endswith('"'):
                filename = filename[:-1]

            ret[filename] = checksum
    return ret


def test_aports_unreferenced_files(args):
    """
    Raise an error if an unreferenced file is found
    """
    for apkbuild_path in glob.iglob(args.aports + "/**/APKBUILD", recursive=True):
        # pmbootstrap parser has some issues with complicated APKBUILDs, skip those.
        if apkbuild_path.startswith(args.aports + "/cross/"):
            continue

        apkbuild = pmb.parse.apkbuild(apkbuild_path)
        sources_chk = parse_source_from_checksums(args, apkbuild_path)

        # Collect files from subpackages
        subpackage_installs = []
        subpackage_triggers = []
        if apkbuild["subpackages"]:
            for subpackage in apkbuild["subpackages"].values():
                if not subpackage:
                    continue
                subpackage_installs += subpackage.get("install", [])
                subpackage_triggers += subpackage.get("triggers", [])

        # Collect trigger files
        trigger_sources = []
        for trigger in apkbuild["triggers"] + subpackage_triggers:
            trigger_sources.append(trigger.split("=")[0])

        dirname = os.path.dirname(apkbuild_path)
        for file in glob.iglob(dirname + "/**", recursive=True):
            rel_file_path = os.path.relpath(file, dirname)
            # Skip APKBUILDs and directories
            if rel_file_path == "APKBUILD" or os.path.isdir(file):
                continue

            if os.path.basename(rel_file_path) not in sources_chk \
                    and rel_file_path not in apkbuild["install"] \
                    and rel_file_path not in subpackage_installs \
                    and rel_file_path not in trigger_sources:
                raise RuntimeError(f"{apkbuild_path}: found unreferenced file: {rel_file_path}")
