#!/usr/bin/env python3
import os
import argparse
import json

import requests

commit_default = os.environ['COMMIT'] if 'COMMIT' in os.environ else None

parser = argparse.ArgumentParser(description='tool to send data to build.postmarketos.org')
parser.add_argument('--token', default='~/.pmos_token', help='secret token to authenticate to build.postmarketos.org')
parser.add_argument('--host', default='https://build.postmarketos.org', help='base url for the submit request')
parser.add_argument('--commit', default=commit_default, help='value for the X-Commit header')
parser.add_argument('--arch', default='x86_64', help='value for the X-Arch header')
parser.add_argument('--id', help='id of the job in the queue, value for the X-Id header')
parser.add_argument('--json', action='store_true', help='datafile is a json file, do extra sanity checks')
parser.add_argument('--verbose', '-v', action='store_true', help='show more debug info')
parser.add_argument('endpoint', help='endpoint name on the API')
parser.add_argument('datafile', help='file containing the data to be submitted', nargs='+')
args = parser.parse_args()

if args.commit is None:
    print('You need to either add COMMIT to the environment or specify --commit')
    exit(1)

if args.verbose:
    print('Environment:')
    print(os.environ)

with open(os.path.expanduser(args.token), encoding="utf-8") as handle:
    secret = handle.read().strip()

url = '{}/api/{}'.format(args.host, args.endpoint)

if args.json:
    if len(args.datafile) > 1:
        print("json mode doesn't support multiple input files")
        exit(1)

    # Send contents of file as HTTP POST with json payload
    with open(args.datafile[0], encoding="utf-8") as handle:
        data = handle.read()
    data = json.loads(data)

    print('Sending json data to {}'.format(url))
    response = requests.post(url, json=data, headers={
        'X-Secret': secret,
        'X-Commit': args.commit,
        'X-Arch': args.arch
    })
else:
    files = []

    for file in args.datafile:
        filename = os.path.basename(file)
        # Send contents of file as HTTP POST with multipart/formdata payload
        files.append(('file[]', (filename, open(args.datafile, 'rb'), 'application/octet-stream')))

        print('Uploading {} to {}'.format(filename, url))

    response = requests.post(url, files=files, headers={
        'X-Secret': secret,
        'X-Commit': args.commit,
        'X-Arch': args.arch,
        'X-Id': args.id
    })

if response.status_code > 399:
    print('Error occured:')
    print(response.content.decode())
    exit(1)

else:
    print(response.content.decode())
