#!/usr/bin/env bash
# 检查 usbeam-hosts-editor 上游最新版本(dogfight360 博客)
# 输出 JSON:{"pkgver": 版本号, "pkgdate": 下载 URL 目录 YYYY/MM}
# 页面含全部历史版本文件的 uploads/YYYY/MM 路径,取最大版本文件所在目录为 pkgdate
set -euo pipefail

url="https://www.dogfight360.com/blog/18627/"

page="$(curl -fsSL "$url")"

# 版本:历史 Linux 包文件名中的最大版本
ver="$(
  echo "$page" \
  | grep -oE 'UsbEAm_Hosts_Editor\.[0-9.]+_[Xx]64\.tar\.gz' \
  | sed -nE 's/^UsbEAm_Hosts_Editor\.//; s/_[Xx]64\.tar\.gz$//p' \
  | sort -V \
  | tail -1
)"

[[ -n "$ver" ]] || { echo "error: 无法从上游页面提取版本" >&2; exit 1; }

# pkgdate:该版本任意平台文件(如 5.0.1_x64.dmg)所在 uploads 目录
pattern="$(echo "$ver" | sed 's/\./\\./g')"
line="$(
  echo "$page" \
  | grep -oE "uploads/[0-9]{4}/[0-9]{2}/UsbEAm_Hosts_Editor[._]V?${pattern}[^\"' <>]*" \
  | tail -1
)"
pkgdate="$(echo "$line" | grep -oE '[0-9]{4}/[0-9]{2}' | head -1)"

[[ -n "$pkgdate" ]] || { echo "error: 无法从上游页面提取 pkgdate" >&2; exit 1; }

jq -n --arg pkgver "$ver" --arg pkgdate "$pkgdate" \
  '{pkgver: $pkgver, pkgdate: $pkgdate}'
