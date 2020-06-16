#!/usr/bin/env python3
# Copyright 2020 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

# Various functions used in CI scripts

import os
import subprocess
import sys


cache = {}


def get_pmaports_dir():
    global cache
    if "pmaports_dir" in cache:
        return cache["pmaports_dir"]
    ret = os.path.realpath(os.path.join(os.path.dirname(__file__) + "/.."))
    cache["pmaports_dir"] = ret
    return ret


def run_git(parameters, check=True, stderr=None):
    """ Run git in the pmaports dir and return the output """
    cmd = ["git", "-C", get_pmaports_dir()] + parameters
    try:
        return subprocess.check_output(cmd, stderr=stderr).decode()
    except subprocess.CalledProcessError:
        if check:
            raise
        return None


def add_upstream_git_remote():
    """ Add a remote pointing to postmarketOS/pmaports. """
    run_git(["remote", "add", "upstream",
             "https://gitlab.com/postmarketOS/pmaports.git"], False)
    run_git(["fetch", "-q", "upstream"])


def commit_message_has_string(needle):
    return needle in run_git(["show", "-s", "--format=full", "HEAD"])


def run_pmbootstrap(parameters, output_return=False):
    """ Run pmbootstrap with the pmaports dir as --aports """
    cmd = ["pmbootstrap", "--aports", get_pmaports_dir()] + parameters
    stdout = subprocess.PIPE if output_return else None
    result = subprocess.run(cmd, stdout=stdout, universal_newlines=True)
    result.check_returncode()
    if output_return:
        return result.stdout


def get_changed_files(removed=True):
    """ Get all changed files and print them, as well as the branch and the
        commit that was used for the diff.
        :param removed: also return removed files (default: True)
        :returns: set of changed files
    """
    commit_head = run_git(["rev-parse", "HEAD"])[:-1]
    commit_upstream_master = run_git(["rev-parse", "upstream/master"])[:-1]
    print("commit HEAD: " + commit_head)
    print("commit upstream/master: " + commit_upstream_master)

    # Check if we are latest upstream/master
    if commit_head == commit_upstream_master:
        # then compare with previous commit
        commit = "HEAD~1"
    else:
        # otherwise compare with latest common ancestor
        commit = run_git(["merge-base", "upstream/master", "HEAD"])[:-1]
    print("comparing HEAD with: " + commit)

    # Changed files
    ret = set()
    print("changed file(s):")
    for file in run_git(["diff", "--name-only", commit, "HEAD"]).splitlines():
        message = "  " + file
        if not os.path.exists(file):
            message += " (deleted)"
            if removed:
                ret.add(file)
        else:
            ret.add(file)
        print(message)
    return ret


def get_changed_packages_sanity_check(count):
    for mark in ["[ci:ignore-count]", "[ci:skip-build]"]:
        if commit_message_has_string(mark):
            print("NOTE: package count sanity check skipped (" + mark + ").")
            return
    if count <= 10:
        return

    print()
    print("ERROR: Too many packages have changed!")
    print()
    print("This is a sanity check, so we don't end up building packages that")
    print("have not been modified. CI won't run for more than one hour")
    print("anyway.")
    print()
    print("Your options:")
    print("a) If you *did not* modify everything listed above, then rebase")
    print("   your branch on the official postmarketOS/pmaports.git master")
    print("   branch. Feel free to ask in the chat for help if you need any.")
    print("b) If you *did* modify all these packages, and you assume that")
    print("   they will build within one hour: skip this sanity check by")
    print("   adding '[ci:ignore-count]' to the commit message (then force")
    print("   push).")
    print("c) If you *did* modify all these packages, and you are sure that")
    print("   they won't build in time, please add '[ci:skip-build]' to the")
    print("   commit message (then force push). Make sure that all packages")
    print("   build with 'pmbootstrap build --strict'!")
    print()
    print("Thank you and sorry for the inconvenience.")

    sys.exit(1)


def get_changed_packages():
    ret = set()
    for file in get_changed_files():
        dirname, filename = os.path.split(file)

        # Skip files:
        # * in the root dir of pmaports (e.g. README.md)
        # * path with a dot (e.g. .gitlab-ci/, device/.shared-patches/)
        if not dirname or file.startswith(".") or "/." in file:
            continue

        if filename != "APKBUILD":
            # Walk up directories until we (eventually) find the package
            # the file belongs to (could be in a subdirectory of a package)
            while dirname and not os.path.exists(os.path.join(dirname, "APKBUILD")):
                dirname = os.path.dirname(dirname)

            # Unable to find APKBUILD the file belong to
            if not dirname:
                # ... maybe the package was deleted entirely?
                if not os.path.exists(file):
                    continue

                # Weird, file does not belong to any package?
                # Here we just warn, there is an extra check
                # to make sure that files are organized properly.
                print(f"WARNING: Changed file {file} does not belong to any package")
                continue

        elif not os.path.exists(file):
            continue  # APKBUILD was deleted

        ret.add(os.path.basename(dirname))

    return ret


def check_build(packages, verify_only=False):
    # Initialize build environment with less logging
    run_pmbootstrap(["build_init"])

    if verify_only:
        run_pmbootstrap(["--details-to-stdout", "checksum", "--verify"] +
                        list(packages))
    else:
        run_pmbootstrap(["--details-to-stdout", "build", "--strict",
                         "--force"] + list(packages))
