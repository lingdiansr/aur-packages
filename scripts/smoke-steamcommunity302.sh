#!/usr/bin/env bash
# steamcommunity302 冒烟测试:s302 是用户唯一入口,shell 层面的缺陷必须真跑一次才发现。
# issue #1 就是例子:app/versions/ 不存在时 glob 无匹配,pipefail + set -e 在 case 分发
# 之前终止脚本,所有子命令(含 GUI)静默 exit 2、零输出 —— 而 makepkg 构建完全正常。
# 用法: scripts/smoke-steamcommunity302.sh <package-dir>
set -euo pipefail

pkgdir="${1:?Usage: smoke-steamcommunity302.sh <package-dir>}"
wrapper="$pkgdir/s302"
[[ -f "$wrapper" ]] || { echo "error: 找不到 $wrapper" >&2; exit 1; }

bash -n "$wrapper" # 语法检查

# 数据目录/配置由脚本自身声明,按它的真实状态断言:
#   - 未初始化(CI 容器、全新机器):必须给出反馈,不得静默退出
#   - 已初始化(开发机):必须真的列出规则(规则库路径解析不对会得到 0 条)
data_dir="$(sed -n 's/^DATA_DIR="\(.*\)"$/\1/p' "$wrapper")"
[[ -n "$data_dir" ]] || { echo "error: 无法从 $wrapper 解析 DATA_DIR" >&2; exit 1; }

out="$(bash "$wrapper" help 2>&1)" || { echo "s302 help 退出码 $?,输出: $out" >&2; exit 1; }
[[ -n "$out" ]] || { echo "s302 help 无输出" >&2; exit 1; }

ver="$(bash "$wrapper" version 2>&1)" || { echo "s302 version 退出码 $?;输出: $ver" >&2; exit 1; }
[[ "$ver" == *steamcommunity302:* ]] || { echo "s302 version 输出缺包版本行: $ver" >&2; exit 1; }

if [[ -f "$data_dir/config.json" ]]; then
    rules="$(bash "$wrapper" rules list 2>&1)" || { echo "s302 rules list 退出码 $?,输出: $rules" >&2; exit 1; }
    count="$(printf '%s\n' "$rules" | grep -o '全部 [0-9]* 条' | grep -o '[0-9]*' || true)"
    if [[ "${count:-0}" -le 0 ]]; then
        echo "s302 rules list 规则数为 ${count:-0}(规则库路径没解析对?):" >&2
        printf '%s\n' "$rules" | tail -2 >&2
        exit 1
    fi
else
    # 首次运行:必须有反馈,而不是无声退出
    if rules="$(bash "$wrapper" rules list 2>&1)"; then
        echo "未初始化时 s302 rules list 不应返回成功: $rules" >&2
        exit 1
    fi
    [[ -n "$rules" ]] || { echo "未初始化时 s302 rules list 没有任何反馈" >&2; exit 1; }
fi

echo "$out" | head -3
echo "$ver"
printf '%s\n' "$rules" | head -2
