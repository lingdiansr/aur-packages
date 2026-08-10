#!/usr/bin/env bash
# 更新包版本:改 pkgver(及派生变量)、重置 pkgrel、重算校验和、重新生成 .SRCINFO
# 用法:update-version.sh <package-name> <new-version>
#
# 有检查脚本(scripts/check-<pkg>.sh)的包,其输出 JSON 为更新变量的单一事实源
# (如 {"pkgver": "14.0.02", "pkgdate": "2026/02"});其他包用传入的 <new-version>。
# 参考:https://github.com/jetm/aur-packages(scripts/update-version.sh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pkg="${1:?Usage: update-version.sh <package-name> <new-version>}"
ver="${2:?Usage: update-version.sh <package-name> <new-version>}"
pkgdir="$REPO_ROOT/$pkg"

if [[ ! -f "$pkgdir/PKGBUILD" ]]; then
  echo "error: $pkgdir/PKGBUILD not found" >&2
  exit 1
fi

echo "Updating $pkg to $ver..."

case "$pkg" in
  maa-unified|steamcommunity302|usbeam-hosts-editor)
    # 以检查脚本输出的 JSON 为准(单一事实源),避免重复抓取解析上游
    json="$("$REPO_ROOT/scripts/check-$pkg.sh")"
    python3 "$REPO_ROOT/scripts/apply-updates.py" "$pkgdir/PKGBUILD" "$json"
    ;;
  *)
    sed -i "s/^pkgver=.*/pkgver=$ver/" "$pkgdir/PKGBUILD"
    ;;
esac

# 版本变化后 pkgrel 重置为 1
sed -i "s/^pkgrel=.*/pkgrel=1/" "$pkgdir/PKGBUILD"

# 重算校验和(下载源文件;git 源为 SKIP)
(cd "$pkgdir" && updpkgsums)

# 重新生成 .SRCINFO
(cd "$pkgdir" && makepkg --printsrcinfo > .SRCINFO)

echo "$pkg updated to $ver"
