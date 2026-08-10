#!/usr/bin/env bash
# 推送更新后的包到 AUR
# 用法:publish.sh <package-name>
#
# 环境变量:
#   AUR_SSH_KEY      AUR 账号注册的 SSH 私钥(未设置则跳过发布)
#   AUR_USER_NAME    提交用户名(默认取 git config)
#   AUR_USER_EMAIL   提交邮箱(默认取 git config)
#
# 参考:https://github.com/jetm/aur-packages(scripts/publish.sh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pkg="${1:?Usage: publish.sh <package-name>}"
pkgdir="$REPO_ROOT/$pkg"

if [[ ! -f "$pkgdir/PKGBUILD" ]] || [[ ! -f "$pkgdir/.SRCINFO" ]]; then
  echo "error: PKGBUILD 或 .SRCINFO 缺失于 $pkgdir" >&2
  exit 1
fi

# AUR 上不存在的包跳过(上传 AUR 后自动生效)
if ! curl -fsSL "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg" | jq -e '.resultcount > 0' >/dev/null 2>&1; then
  echo "$pkg 不在 AUR 上,跳过发布"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# SSH 配置(幂等)
setup_ssh() {
  if [[ -n "${AUR_SSH_KEY:-}" ]]; then
    local keyfile="$tmp/aur_ssh_key"
    # 去除 CR(Windows 粘贴的密钥会 CRLF,ssh 报 invalid format)
    # umask 保证写入时私钥不可被他人读
    (
      umask 077
      printf '%s\n' "$AUR_SSH_KEY" | tr -d '\r' >"$keyfile"
    )

    # 私钥必须可解析且无口令(下方 ssh 无 agent 无法应答口令)
    if ! ssh-keygen -y -f "$keyfile" >/dev/null 2>&1; then
      echo "error: AUR_SSH_KEY 不是可用的私钥。" >&2
      echo "  需为私钥本体(非 .pub)、未加密、换行完整。推荐:" >&2
      echo "    gh secret set AUR_SSH_KEY < ~/.ssh/aur" >&2
      exit 1
    fi

    export GIT_SSH_COMMAND="ssh -i $keyfile -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  fi
}

setup_git_identity() {
  : "${AUR_USER_NAME:=$(git config user.name 2>/dev/null || true)}"
  : "${AUR_USER_EMAIL:=$(git config user.email 2>/dev/null || true)}"
  if [[ -z "$AUR_USER_NAME" ]] || [[ -z "$AUR_USER_EMAIL" ]]; then
    echo "error: git user.name/user.email 未配置且 AUR_USER_NAME/AUR_USER_EMAIL 未设置" >&2
    exit 1
  fi
  git config --global user.name "$AUR_USER_NAME"
  git config --global user.email "$AUR_USER_EMAIL"
}

setup_ssh
setup_git_identity

echo "Publishing $pkg to AUR..."

git clone "ssh://aur@aur.archlinux.org/$pkg.git" "$tmp/$pkg"
# AUR 只接受 master 分支;新(空)仓库需要显式创建
git -C "$tmp/$pkg" checkout -B master 2>/dev/null || true

cp "$pkgdir/PKGBUILD" "$tmp/$pkg/"
cp "$pkgdir/.SRCINFO" "$tmp/$pkg/"

# 收集包所需的本地文件:source 中非 URL 项 + install/changelog
# 从 .SRCINFO 读取(AUR 服务端 hook 检查的正是这些)
if ! wanted_raw=$(
  awk -F' = ' '
    $1 ~ /^[[:space:]]*(source(_[a-zA-Z0-9_]+)?|install|changelog)$/ {
      v = $2
      if (v ~ /:\/\//) next
      sub(/^.*::/, "", v)
      if (v != "") print v
    }
  ' "$pkgdir/.SRCINFO" | sort -u
); then
  echo "error: 解析 $pkgdir/.SRCINFO 的本地源文件列表失败" >&2
  exit 1
fi

wanted=()
if [[ -n $wanted_raw ]]; then
  mapfile -t wanted <<<"$wanted_raw"
fi

# 交叉校验:声明了本地文件但解析为空说明解析逻辑失效
declared_local=$(grep -E \
  '^[[:space:]]*(source(_[a-zA-Z0-9_]+)?|install|changelog) = ' \
  "$pkgdir/.SRCINFO" 2>/dev/null | grep -vc '://' || true)
if [[ ${declared_local:-0} -gt 0 ]] && ((${#wanted[@]} == 0)); then
  echo "error: $pkgdir/.SRCINFO 声明了 $declared_local 个本地源文件但解析为空,拒绝发布" >&2
  exit 1
fi

missing=()
if ((${#wanted[@]} > 0)); then
  for name in "${wanted[@]}"; do
    if [[ -f "$pkgdir/$name" ]]; then
      cp "$pkgdir/$name" "$tmp/$pkg/"
    else
      missing+=("$name")
    fi
  done
fi

if ((${#missing[@]} > 0)); then
  echo "error: .SRCINFO 列出了 $pkgdir 中不存在的本地文件:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo "  AUR 会拒绝缺少源文件的提交。" >&2
  exit 1
fi

cd "$tmp/$pkg"

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  echo "$pkg: 无变更,跳过发布"
  exit 0
fi

version=$(grep -m1 '^pkgver=' PKGBUILD | cut -d= -f2)
git add -A
git commit -m "Update to $version"
git push

echo "$pkg 已发布到 AUR (version $version)"
