#!/usr/bin/env python3
# Copyright 2018 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import os
import subprocess
import sys


def get_pmaports_dir():
    return os.path.realpath(os.path.join(os.path.dirname(__file__) + "/.."))


def run_git(parameters):
    """ Run git in the pmaports dir and return the output """
    cmd = ["git", "-C", get_pmaports_dir()] + parameters
    return subprocess.check_output(cmd).decode()


def run_pmbootstrap(parameters):
    """ Run pmbootstrap with the pmaports dir as --aports """
    cmd = ["pmbootstrap", "--aports", get_pmaports_dir()] + parameters
    process = subprocess.Popen(cmd)
    process.communicate()
    if process.returncode != 0:
        print("** Building failed")
        exit(1)


def get_changed_files():
    """ Get all changed files and print them, as well as the branch and the
        commit that was used for the diff.
        :returns: list of changed files
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
    ret = run_git(["diff", "--name-only", commit, "HEAD"]).splitlines()
    print("changed file(s):")
    for file in ret:
        print("  " + file)
    return ret


def get_changed_packages():
    files = get_changed_files()
    ret = set()
    for file in files:
        # Skip files in the root dir of pmaports as well as dirs beginning with
        # a dot (.gitlab-ci/)
        if "/" not in file or file.startswith("."):
            continue

        # Add to the ret set (removes duplicated automatically)
        ret.add(file.split("/")[1])

    if len(ret) > 10:
        print("ERROR: Too many packages have changed!")
        print("This is a sanity check, so we don't end up building packages"
              " that have not been modified. CI won't run for more than one"
              " hour anyway.")
        print("If you see this message on your personal fork of the"
              " pmbootstrap repository, try to update your fork's master"
              " branch to the upstream master branch.")
        sys.exit(1)
    return ret


def check_build(packages):
    # Initialize build environment with less logging
    run_pmbootstrap(["build_init"])
    run_pmbootstrap(["--details-to-stdout", "build", "--strict", "--force"] +
                    list(packages))


if __name__ == "__main__":
    # Add a remote pointing to postmarketOS/pmaports for later
    run_git(["remote", "add", "upstream",
             "https://gitlab.com/postmarketOS/pmaports.git"])
    run_git(["fetch", "-q", "upstream"])

    # Build changed packages
    packages = get_changed_packages()
    if len(packages) == 0:
        print("no aports changed in this branch")
    else:
        print("building in strict mode: " + ", ".join(packages))
        check_build(packages)
