#!/usr/bin/env bash
# 检查 steamcommunity302 上游最新版本(dogfight360 博客)
# 输出 JSON:{"pkgver": 版本号, "pkgdate": 下载 URL 目录 YYYY/MM}
# 页面含全部历史版本文件名(steamcommunity_302_Linux_AMD64_V<ver>.tar.gz)
# 与版本块("下载: (V14.0.02 [20260201])"),均取最大版本
set -euo pipefail

url="https://www.dogfight360.com/blog/18682/"

page="$(curl -fsSL "$url")"

# 版本:历史 Linux 包文件名中的最大版本
ver="$(
  echo "$page" \
  | grep -oE 'steamcommunity_302_Linux_AMD64_V[0-9.]+\.tar\.gz' \
  | sed -nE 's/^steamcommunity_302_Linux_AMD64_V//; s/\.tar\.gz$//p' \
  | sort -V \
  | tail -1
)"

# pkgdate:版本块 "V<ver> [YYYYMMDD]" 中最大版本对应的日期
block="$(echo "$page" | grep -oE 'V[0-9]+\.[0-9]+\.[0-9]+ \[[0-9]{8}\]' | sort -V | tail -1)"
pkgdate="$(echo "$block" | sed -nE 's/.*\[([0-9]{4})([0-9]{2})[0-9]{2}\]/\1\/\2/p')"

[[ -n "$ver" ]] || { echo "error: 无法从上游页面提取版本" >&2; exit 1; }
[[ -n "$pkgdate" ]] || { echo "error: 无法从上游页面提取 pkgdate" >&2; exit 1; }

jq -n --arg pkgver "$ver" --arg pkgdate "$pkgdate" \
  '{pkgver: $pkgver, pkgdate: $pkgdate}'
