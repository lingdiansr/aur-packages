#!/usr/bin/env bash
# Check the newest version tag of srun-portal and emit it as pkgver.
#
# 上游 tag 是 v<semver>,Release 资产名把版本原样嵌入
# (srun-portal-v<ver>-x86_64-unknown-linux-gnu),PKGBUILD 用 $pkgver 派生该 URL,
# 所以这里只需给出 pkgver;资产命名若改变必须同步改 PKGBUILD 的 source。
set -euo pipefail

repo='https://github.com/lingdiansr/srun-portal.git'

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
    match = re.fullmatch(r"v([0-9][0-9A-Za-z._]*)", tag)
    if not match:
        continue
    version = match.group(1)
    # 按版本分量做数值排序,避免 0.10.0 排在 0.9.0 之前
    key = tuple(int(part) if part.isdigit() else part
                for part in re.split(r"[._-]", version))
    candidates.append((key, version))

if not candidates:
    raise SystemExit("error: no usable version tags found")

# 数值与非数值分量混排时 tuple 比较会抛 TypeError,退回字符串序
try:
    version = sorted(candidates, key=lambda item: item[0])[-1][1]
except TypeError:
    version = sorted(candidates, key=lambda item: item[1])[-1][1]

json.dump({"pkgver": version}, sys.stdout)
print()
'
