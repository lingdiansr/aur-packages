#!/usr/bin/env bash
# 检查 ffyfox/dsh-desktop-linux 最新的 Linux amd64 deb 产物。
# 输出 JSON:{"pkgver": "0.2.1alpha.2", "_debrel": "v0.2.1alpha2",
#            "_debname": "deepseek-harness-0.2.1-alpha.2-linux-amd64-unsigned.deb"}
#
# 该 fork 把上游 deepseek-ai/deepseek-harness 的桌面端移植到 Linux 后打补丁构建,
# 每个 Release 同时提供 deb/AppImage/rpm;本包只封装 deb(PKGBUILD 顶部有理由),
# 所以候选集是带 amd64 deb 的 Release,其余产物忽略。
#
# pkgver 取 deb 文件名里的版本串并去掉连字符(0.2.1-alpha.2 → 0.2.1alpha.2):
# Arch 的 pkgver 不允许出现连字符。_debrel 是 Release tag,与 _debname 一起
# 组成 PKGBUILD 里的下载 URL —— 两者都不存在子串关系,必须各自取。
#
# Release 里可能混有历史版本线(如 0.1.7rc2 的补丁发布在 0.2.0 之后),因此按
# 版本比较取最大值,而不是取 API 返回的第一项;比较用 pacman vercmp 语义。
set -euo pipefail

api='https://api.github.com/repos/ffyfox/dsh-desktop-linux/releases?per_page=100'

# 有 GITHUB_TOKEN 时带上(CI 里由 workflow 提供),避免匿名请求撞速率限制
auth=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "${auth[@]}" -H 'Accept: application/vnd.github+json' "$api" -o "$tmp"

python3 - "$tmp" <<'PY'
import json
import re
import sys

# deb 文件名:deepseek-harness-<version>-linux-amd64-unsigned.deb,<version> 如 0.2.1-alpha.2
asset_re = re.compile(r"^deepseek-harness-(.+)-linux-amd64-unsigned\.deb$")
# 预发布标识的先后顺序(与 semver 一致),未知标识排在已知的之后、数字进位之前
stage_rank = {"alpha": 0, "beta": 1, "rc": 2}


def version_key(version):
    """把 <数字核心>[-<标识>.<序号>] 映射成可比大小的元组。

    数字核心逐段按数值比较;预发布标识整体低于同名数字核心的正式版
    (0.2.1alpha.2 < 0.2.1),标识之间按 alpha < beta < rc 排。
    """
    core, _, pre = version.partition("-")
    numbers = tuple(int(part) for part in re.findall(r"\d+", core))
    if not pre:
        return (numbers, 1)
    m = re.fullmatch(r"([a-z]+)\.?(\d+)", pre)
    if not m:
        sys.exit(f"error: 无法解析预发布标识: {version}")
    return (numbers, 0, stage_rank.get(m.group(1), len(stage_rank)), int(m.group(2)))


with open(sys.argv[1]) as f:
    releases = json.load(f)

if not isinstance(releases, list) or not releases:
    sys.exit("error: GitHub releases API 返回异常(不是非空数组)")

candidates = []
for release in releases:
    for asset in release.get("assets") or []:
        m = asset_re.fullmatch(asset["name"])
        if m:
            candidates.append((version_key(m.group(1)), release["tag_name"], asset["name"], m.group(1)))

if not candidates:
    sys.exit("error: 没有任何 Release 提供 linux-amd64 的 deb 产物")

_, tag, debname, version = max(candidates)
json.dump({"pkgver": version.replace("-", ""), "_debrel": tag, "_debname": debname}, sys.stdout)
print()
PY
