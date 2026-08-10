#!/usr/bin/env bash
# 检查 maa-unified 上游最新版本(fork Release asset 名)
# 输出 JSON:{"pkgver": <assetver>.r0.g<commit>, "_assetver": ..., "_commit": ...}
# 主仓 CI 产物无法匿名获取,版本由 fork(lingdiansr/MaaAssistantArknights)的
# Release(固定 tag maaunified-linux-x64)的 asset 名编码:
#   MAAUnified-v<assetver>-<commit>-linux-x64.tar.gz
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

assetver="$(echo "$asset" | sed -nE 's/^MAAUnified-v([0-9.]+)-[0-9a-f]+-linux-x64\.tar\.gz$/\1/p')"
commit="$(echo "$asset" | sed -nE 's/^MAAUnified-v[0-9.]+-([0-9a-f]+)-linux-x64\.tar\.gz$/\1/p')"

[[ -n "$assetver" && -n "$commit" ]] || { echo "error: 无法解析 asset 名 $asset" >&2; exit 1; }

jq -n --arg pkgver "${assetver}.r0.g${commit}" --arg assetver "$assetver" --arg commit "$commit" \
  '{pkgver: $pkgver, _assetver: $assetver, _commit: $commit}'
