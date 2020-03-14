#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later

import common
import os.path
import subprocess
import sys

if __name__ == "__main__":
    common.add_upstream_git_remote()
    apkbuilds = {file for file in common.get_changed_files(removed=False)
                 if os.path.basename(file) == "APKBUILD"}
    if len(apkbuilds) < 1:
        print("No APKBUILDs to lint")
        sys.exit(0)

    issues = []
    for apkbuild in apkbuilds:
        if apkbuild.startswith("temp/") or apkbuild.startswith("cross/"):
            print(f"NOTE: Skipping linting of {apkbuild}")
            continue

        result = subprocess.run(["apkbuild-lint", apkbuild], capture_output=True)
        if len(result.stdout) > 0:
            issues.append([apkbuild, result.stdout.decode("utf-8")])

    if len(issues) > 0:
        print("Linting issues found:")
        for issue in issues:
            print(issue[0] + ": " + issue[1])

        sys.exit(1)
