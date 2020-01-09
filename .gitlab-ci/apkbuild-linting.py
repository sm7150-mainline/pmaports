#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later

import common
import subprocess
import sys

if __name__ == "__main__":
    common.add_upstream_git_remote()
    packages = common.get_changed_packages(with_directory=True)

    if len(packages) < 1:
        print("No APKBUILDs to lint")
        sys.exit(0)

    issues = []
    for package in packages:
        if "temp/" in package or "APKBUILD" not in package:
            continue

        result = subprocess.run(["apkbuild-lint", package], capture_output=True)
        if len(result.stdout) > 0:
            issues.append([package, result.stdout.decode("utf-8")])

    if len(issues) > 0:
        print("Linting issues found:")
        for issue in issues:
            print(issue[0] + ": " + issue[1])

        sys.exit(1)
