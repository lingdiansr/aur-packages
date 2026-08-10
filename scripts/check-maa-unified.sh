#!/usr/bin/env bash
# 解析 maa-unified 上游最新版本(fork Release asset 名)
# 输出 pkgver 格式: <assetver>.r0.g<commit>,如 6.16.7.r0.gc6bdb48c7
set -euo pipefail

REPO="lingdiansr/MaaAssistantArknights"
TAG="maaunified-linux-x64"

asset="$(
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" \
  | jq -r '.assets[].name' \
  | grep -E '^MAAUnified-v[0-9.]+-[0-9a-f]+-linux-x64\.tar\.gz$' \
  | head -1
)"

[[ -n "$asset" ]] || { echo "error: 未找到 MAAUnified asset" >&2; exit 1; }

echo "$asset" | sed -E 's/^MAAUnified-v([0-9.]+)-([0-9a-f]+)-linux-x64\.tar\.gz$/\1.r0.g\2/'
