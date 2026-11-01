#!/usr/bin/env bash
# Check the newest version tag and convert it to an Arch-compatible pkgver.
set -euo pipefail

repo='https://github.com/lingdiansr/fpc-disum-driver.git'

git ls-remote --tags --refs "$repo" 'v*' |
  awk -F/ '{print $3}' |
  python3 -c '
import json
import re
import sys

tags = [line.strip() for line in sys.stdin if line.strip()]
if not tags:
    raise SystemExit("error: no version tags found")

candidates = []
for tag in tags:
    match = re.fullmatch(r"v([0-9][0-9A-Za-z._-]*)", tag)
    if not match:
        continue
    version = match.group(1)
    arch_version = version.replace("-", "_")
    candidates.append((arch_version, tag))

if not candidates:
    raise SystemExit("error: no usable version tags found")

version, tag = sorted(candidates, key=lambda item: item[0])[-1]
json.dump({"_tag": tag, "pkgver": version}, sys.stdout)
print()
'
