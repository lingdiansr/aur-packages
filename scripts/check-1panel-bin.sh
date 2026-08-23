#!/usr/bin/env bash
# 检查 1Panel v2 上游最新版本(官方 CDN)
# 输出 JSON:{"pkgver": "2.2.5", "_upver": "v2.2.5"}
# 版本端点与官方安装脚本一致;用快镜像 fit2cloud(官方脚本默认的
# resource.1panel.pro 对部分网络极慢)
set -euo pipefail

url="https://resource.fit2cloud.com/1panel/package/v2/stable/latest"

ver="$(curl -fsSL "$url")"

[[ "$ver" =~ ^v[0-9]+(\.[0-9]+)+$ ]] || { echo "error: 版本格式异常($ver)" >&2; exit 1; }

jq -n --arg pkgver "${ver#v}" --arg upver "$ver" \
  '{pkgver: $pkgver, _upver: $upver}'
