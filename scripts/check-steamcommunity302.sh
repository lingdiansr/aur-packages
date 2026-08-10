#!/usr/bin/env bash
# 检查 steamcommunity302 上游最新版本(dogfight360 博客)
# 页面含全部历史版本文件名(如 steamcommunity_302_Linux_AMD64_V13.0.03.tar.gz),
# 取最大版本即最新。输出版本号,如 14.0.02
set -euo pipefail

url="https://www.dogfight360.com/blog/18682/"

ver="$(
  curl -fsSL "$url" \
  | grep -oE 'steamcommunity_302_Linux_AMD64_V[0-9.]+\.tar\.gz' \
  | sed -nE 's/^steamcommunity_302_Linux_AMD64_V//; s/\.tar\.gz$//p' \
  | sort -V \
  | tail -1
)"

[[ -n "$ver" ]] || { echo "error: 无法从上游页面提取版本" >&2; exit 1; }
echo "$ver"
