#!/usr/bin/env bash
# 检查 usbeam-hosts-editor 上游最新版本(dogfight360 博客)
# 页面含全部历史版本文件名(如 UsbEAm_Hosts_Editor.5.0.1_X64.tar.gz),
# 取最大版本即最新。输出版本号,如 5.0.1
set -euo pipefail

url="https://www.dogfight360.com/blog/18627/"

ver="$(
  curl -fsSL "$url" \
  | grep -oE 'UsbEAm_Hosts_Editor\.[0-9.]+_[Xx]64\.tar\.gz' \
  | sed -nE 's/^UsbEAm_Hosts_Editor\.//; s/_[Xx]64\.tar\.gz$//p' \
  | sort -V \
  | tail -1
)"

[[ -n "$ver" ]] || { echo "error: 无法从上游页面提取版本" >&2; exit 1; }
echo "$ver"
