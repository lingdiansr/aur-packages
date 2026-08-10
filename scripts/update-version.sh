#!/usr/bin/env bash
# 更新包版本:改 pkgver、重置 pkgrel、重算校验和、重新生成 .SRCINFO
# 用法:update-version.sh <package-name> <new-version>
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
  maa-unified)
    # pkgver 是模板 pkgver=${_assetver}.r0.g${_commit},ver 形如 6.16.7.r0.gc6bdb48c7
    # 只更新 _assetver/_commit 两个变量,保持 PKGBUILD 结构不变
    assetver="${ver%%.r0.g*}"
    commit="${ver##*.r0.g}"
    [[ -n "$assetver" && -n "$commit" ]] || { echo "error: 无法解析版本 $ver" >&2; exit 1; }
    sed -i "s/^_assetver=.*/_assetver=$assetver/" "$pkgdir/PKGBUILD"
    sed -i "s/^_commit=.*/_commit=$commit/" "$pkgdir/PKGBUILD"
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
