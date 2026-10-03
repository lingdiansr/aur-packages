#!/usr/bin/env bash
# 检查 SteamCommunity302 上游最新 AppImage 版本。
# 输出 JSON: {"pkgver": "版本号"}。
set -euo pipefail

url="https://www.dogfight360.com/blog/18682/"

# dogfight360.com 在代理环境中可能 TLS 握手失败；版本检查必须直连，
# 且只影响本次 curl，不改变调用者的代理环境。
page="$(
  env -u http_proxy -u https_proxy -u all_proxy \
      -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      -u no_proxy -u NO_PROXY \
      curl -fsSL "$url"
)"

# 页面可能保留历史下载链接。只接受两种当前 AppImage 文件名，去重并选
# 版本最高的一项，确保 nvchecker 收到单一 pkgver。
versions="$(
  printf '%s\n' "$page" |
    grep -oE 'Steamcommunity_302_[0-9]+(\.[0-9]+)+_Linux_WebKit_(x64|arm64)\.AppImage' |
    sed -E 's/^Steamcommunity_302_([0-9.]+)_Linux_WebKit_(x64|arm64)\.AppImage$/\1/' |
    sort -Vu
)" || true
ver="$(printf '%s\n' "$versions" | tail -n 1)"

[[ -n "$ver" ]] || {
  echo "error: 无法从上游页面提取 AppImage 版本" >&2
  exit 1
}

jq -n --arg pkgver "$ver" '{pkgver: $pkgver}'
