#!/usr/bin/env bash
# 更新包版本:改 pkgver、重置 pkgrel、重算校验和、重新生成 .SRCINFO
# 用法:update-version.sh <package-name> <new-version>
# 参考:https://github.com/jetm/aur-packages(scripts/update-version.sh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# dogfight360 博客文章页:版本块形如 "下载: (V14.0.02 [20260201])"
S302_URL="https://www.dogfight360.com/blog/18682/"
# usbeam 页面:当前版本文件 URL 形如 uploads/2026/01/UsbEAm_Hosts_Editor.5.0.1_x64.dmg
UHE_URL="https://www.dogfight360.com/blog/18627/"

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
  steamcommunity302)
    # 下载 URL 形如 uploads/<pkgdate>/steamcommunity_302_Linux_AMD64_V<pkgver>.tar.gz,
    # pkgdate(YYYY/MM)与版本绑定,从页面版本块提取
    sed -i "s/^pkgver=.*/pkgver=$ver/" "$pkgdir/PKGBUILD"
    block="$(curl -fsSL "$S302_URL" | grep -oE 'V[0-9]+\.[0-9]+\.[0-9]+ \[[0-9]{8}\]' | sort -V | tail -1)"
    pkgdate="$(echo "$block" | sed -nE 's/.*\[([0-9]{4})([0-9]{2})[0-9]{2}\]/\1\/\2/p')"
    [[ -n "$pkgdate" ]] || { echo "error: 无法从上游页面提取 pkgdate" >&2; exit 1; }
    # pkgdate 形如 2026/02 含斜杠,用 | 作 sed 分隔符
    sed -i "s|^pkgdate=.*|pkgdate=$pkgdate|" "$pkgdir/PKGBUILD"
    ;;
  usbeam-hosts-editor)
    # 下载 URL 形如 uploads/<pkgdate>/UsbEAm_Hosts_Editor.5.0.1_x64.dmg,
    # pkgdate(YYYY/MM)取最大版本文件的 uploads 目录
    sed -i "s/^pkgver=.*/pkgver=$ver/" "$pkgdir/PKGBUILD"
    block="$(curl -fsSL "$UHE_URL" | grep -oE 'uploads/[0-9]{4}/[0-9]{2}/UsbEAm_Hosts_Editor[._]V?[0-9.]+[^"'"'"' <>]*' | sort -V | tail -1)"
    pkgdate="$(echo "$block" | grep -oE '[0-9]{4}/[0-9]{2}' | head -1)"
    [[ -n "$pkgdate" ]] || { echo "error: 无法从上游页面提取 pkgdate" >&2; exit 1; }
    sed -i "s|^pkgdate=.*|pkgdate=$pkgdate|" "$pkgdir/PKGBUILD"
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
