#!/usr/bin/env bash
# SecureLink(网宿 SDP 客户端)更新检查——能力边界说明:
#
# 1. 官网(www.wangsu.com / en.wangsu.com / 文档中心)对非浏览器流量返回 406
#    (网宿 WAF 按 TLS 指纹拦截,curl 无法绕过),页面本身也只写"版本描述"不含版本号
# 2. 下载服务器(download-sdwan.wangsu.com)无目录索引、无 Packages/version 清单、
#    无 latest 固定入口;deb 文件名精确绑定版本(SecureLink-ubuntu-x64-<ver>-66.deb),
#    无法枚举相邻版本
# 3. 结论:无法自动获取新版本号,本脚本退化为"存在性检查":
#    - 当前 PKGBUILD 的 deb URL 可下载 → 输出当前版本(表示无更新信号)
#    - 已失效(404) → 说明版本已下线,大概率有新版本,报错提醒手动检查官网
set -euo pipefail

pkgdir="$(cd "$(dirname "$0")/.." && pwd)/securelink"

ver="$(grep -m1 '^pkgver=' "$pkgdir/PKGBUILD" | cut -d= -f2)"
url="https://download-sdwan.wangsu.com/public/securelink/pkg/formal/COMMON/ubuntuX64/SecureLink-ubuntu-x64-${ver}-66.deb"

if curl -fsS -o /dev/null "$url"; then
  echo "$ver"
else
  echo "error: SecureLink 下载 URL 失效(版本 $ver 可能已下线),请手动检查官网 https://www.wangsu.com/app/securelink" >&2
  exit 1
fi
