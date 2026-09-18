#!/usr/bin/env bash
# 冒烟测试分发:执行 scripts/smoke-<pkg>.sh(该包没有则跳过)。
# 调用点:
#   - .github/workflows/check-updates.yml 的 update job(构建验证之后)
#   - .github/workflows/publish-aur.yml(发布到 AUR 之前)
# 后者覆盖"只改包内文件、上游没有新版本"这类不会被 nvchecker 检出更新的提交 ——
# 它们不会进 update job 的 matrix,issue #1 的静默退出就是这样漏到 AUR 的。
# 用法: scripts/smoke.sh <package-name>
set -euo pipefail

pkg="${1:?Usage: smoke.sh <package-name>}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

[[ -d "$repo_root/$pkg" ]] || { echo "error: 无此包目录: $repo_root/$pkg" >&2; exit 1; }

script="$repo_root/scripts/smoke-$pkg.sh"
if [[ ! -f "$script" ]]; then
    echo "$pkg: 无冒烟测试脚本,跳过"
    exit 0
fi

echo "==> $pkg 冒烟测试"
bash "$script" "$repo_root/$pkg"
