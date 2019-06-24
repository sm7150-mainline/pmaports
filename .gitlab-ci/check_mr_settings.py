#!/usr/bin/env python3
# Copyright 2019 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import argparse
import json
import os
import sys
import urllib.parse
import urllib.request


def check_environment_variables():
    """ Make sure that all environment variables from GitLab CI are present,
        and exit right here when a variable is missing. """
    keys = ["CI_MERGE_REQUEST_IID",
            "CI_MERGE_REQUEST_PROJECT_PATH",
            "CI_MERGE_REQUEST_SOURCE_PROJECT_URL"]
    for key in keys:
        if key in os.environ:
            continue
        print("ERROR: missing environment variable: " + key)
        print("Reference: https://docs.gitlab.com/ee/ci/variables/")
        exit(1)


def get_url_api():
    """ :returns: single merge request API URL, as documented here:
        https://docs.gitlab.com/ee/api/merge_requests.html#get-single-mr """
    project_path = os.environ["CI_MERGE_REQUEST_PROJECT_PATH"]
    project_path = urllib.parse.quote_plus(project_path)
    mr_id = os.environ["CI_MERGE_REQUEST_IID"]

    url = "https://gitlab.com/api/v4/projects/{}/merge_requests/{}"
    return url.format(project_path, mr_id)


def get_url_mr_edit():
    """ :returns: the link where the user can edit their own MR """
    url = "https://gitlab.com/{}/merge_requests/{}/edit"
    return url.format(os.environ["CI_MERGE_REQUEST_PROJECT_PATH"],
                      os.environ["CI_MERGE_REQUEST_IID"])


def get_url_repo_settings():
    """ :returns: link to the user's forked pmaports project's settings """
    prefix = os.environ["CI_MERGE_REQUEST_SOURCE_PROJECT_URL"]
    return prefix + "/settings/repository"


def get_mr_settings(path):
    """ Get the merge request API data and parse it as JSON. Print the whole
        thing on failure.

        :param path: to a local file with the saved API data (will download a
                     fresh copy when set to None)
        :returns: dict of settings data (see GitLab API reference) """
    content = ""
    if path:
        # Read file
        with open(path, encoding="utf-8") as handle:
            content = handle.read()
    else:
        # Download from GitLab API
        url = get_url_api()
        print("Download " + url)
        content = urllib.request.urlopen(url).read().decode("utf-8")

    # Parse JSON
    try:
        return json.loads(content)
    except:
        print("ERROR: failed to decode JSON. Here's the whole content for"
              " debugging:")
        print("---")
        print(content)
        exit(1)


def settings_read(settings, key):
    if key not in settings:
        print("ERROR: missing '" + key + "' key in settings!")
        print("Here are the whole settings for debugging:")
        print("---")
        print(settings)
        exit(1)
    return settings[key]


def check_allow_push(settings):
    """ :returns: True when maintainers are allowed to push to the branch
                  (what we want!), False otherwise """

    # Check if source branch is in same repository
    source = settings_read(settings, "source_project_id")
    target = settings_read(settings, "target_project_id")
    if source == target:
        return True

    return settings_read(settings, "allow_maintainer_to_push")


def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", help="use a local file instead of querying"
                        " the GitLab API", default=None)
    args = parser.parse_args()

    # Check the merge request
    check_environment_variables()
    settings = get_mr_settings(args.path)

    # Make sure that squashing is disabled
    if settings_read(settings, "squash"):
        print("*** MR settings check failed!")
        print('ERROR: Please turn off the "Squash commits when merge request'
              ' is accepted." option in the merge request settings.')
        return 1
    if check_allow_push(settings):
        print("*** MR settings check successful!")
    else:
        print("*** MR settings check failed!")
        print()
        print("We need to be able to push changes to your merge request.")
        print("So we can rebase it on master right before merging, add the")
        print("MR-ID to the commit messages, etc.")
        print()
        print("How to fix it:")
        print("1) Open the 'edit' page of your merge request:")
        print("   " + get_url_mr_edit())
        print("2) Enable this option and save:")
        print("   'Allow commits from members who can merge to the target"
              " branch'")
        print("3) Run these tests again with an empty commit in your MR:")
        print("   $ git commit --allow-empty -m 'run mr-settings test again'")
        print()
        print("If that setting is disabled, then you have created the MR from")
        print("a protected branch. When you had forked the repository from")
        print("postmarketOS, the protected branch settings were copied to")
        print("your fork.")
        print()
        print("Resolve this with:")
        print("1) Open your repository settings:")
        print("   " + get_url_repo_settings())
        print("2) Scroll down to 'Protected Branches' and expand it")
        print("3) Click 'unprotect' next to the branch from your MR")
        print("4) Follow steps 1-3 from the first list again, the option")
        print("   should not be disabled anymore.")
        print()
        print("Thank you and sorry for the inconvenience.")
        return 1
    return 0


sys.exit(main())
