#!/usr/bin/env python3
# Copyright 2019 Martijn Braam
# Copyright 2019 Oliver Smith
# SPDX-License-Identifier: GPL-3.0-or-later

import json
import os
import requests

# Require environment vars
for key in ["BPO_API_ENDPOINT",
            "BPO_API_HOST",
            "BPO_ARCH",
            "BPO_BRANCH",
            "BPO_TOKEN_FILE",
            "BPO_PAYLOAD_FILES",    # one file per line
            "BPO_PAYLOAD_IS_JSON",  # set to "1" to enable
            "BPO_PKGNAME",
            "BPO_VERSION",          # $pkgver-r$pkgrel
            ]:
    if key not in os.environ:
        print("ERROR: missing environment variable: " + key)
        exit(1)

# Parse and check files
files = os.environ["BPO_PAYLOAD_FILES"].split("\n")
for path in files:
    if not os.path.exists(path):
        print("ERROR: file not found: " + path)
        exit(1)

# Load token
with open(os.path.expanduser(os.environ["BPO_TOKEN_FILE"]),
          encoding="utf-8") as handle:
    token = handle.read().strip()

# Load other env vars
url = (os.environ["BPO_API_HOST"] + "/api/job-callback/" +
       os.environ["BPO_API_ENDPOINT"])
is_json = (os.environ["BPO_PAYLOAD_IS_JSON"] == "1")

# Prepare HTTP headers
headers = {"X-BPO-Arch": os.environ["BPO_ARCH"],
           "X-BPO-Branch": os.environ["BPO_BRANCH"],
           "X-BPO-Token": token,
           "X-BPO-Pkgname": os.environ["BPO_PKGNAME"],
           "X-BPO-Version": os.environ["BPO_VERSION"]}

# Submit JSON
if is_json:
    if len(files) > 1:
        print("ERROR: json mode doesn't support multiple input files")
        exit(1)

    # Send contents of file as HTTP POST with json payload
    with open(files[0], encoding="utf-8") as handle:
        data = handle.read()
    data = json.loads(data)

    print("Sending JSON to: " + url)
    response = requests.post(url, json=data, headers=headers)
else:  # Submit blobs
    blobs = []
    for path in files:
        print("Appending: " + path)
        filename = os.path.basename(path)
        # Send contents of file as HTTP POST with multipart/formdata payload
        blobs.append(("file[]", (filename,
                                 open(path, "rb"),
                                 "application/octet-stream")))

    print("Uploading to: " + url)
    response = requests.post(url, files=blobs, headers=headers)

if response.status_code > 399:
    print("Error occurred:")
    print(response.content.decode())
    exit(1)
else:
    print(response.content.decode())
