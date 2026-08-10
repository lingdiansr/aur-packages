#!/usr/bin/env python3
"""将更新 JSON 的 key 遍历应用到 PKGBUILD。

用法: apply-updates.py <PKGBUILD 路径> <更新 JSON 字符串>

- 对 JSON 的每个 key,在 PKGBUILD 中查找 `^key=` 行并整体替换为 `key=value`
- 特判:pkgver 为模板行(值含 `${`,如 `pkgver=${_assetver}.r0.g${_commit}`)时
  跳过,其值由派生变量(_assetver/_commit 等)生成,避免破坏模板结构
- PKGBUILD 中不存在的 key 仅告警,不中断
"""
import json
import re
import sys

TEMPLATE_VAR = re.compile(r'\$\{')


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <PKGBUILD> <updates-json>", file=sys.stderr)
        return 2

    pkgbuild_path, updates_json = sys.argv[1], sys.argv[2]
    try:
        updates = json.loads(updates_json)
    except json.JSONDecodeError as e:
        print(f"error: 更新 JSON 解析失败: {e}", file=sys.stderr)
        return 1
    if not isinstance(updates, dict) or not updates:
        print("error: 更新 JSON 必须为非空对象", file=sys.stderr)
        return 1

    with open(pkgbuild_path) as f:
        lines = f.readlines()

    pkgver_line = next((l for l in lines if l.startswith("pkgver=")), None)
    pkgver_is_template = bool(pkgver_line and TEMPLATE_VAR.search(pkgver_line))

    applied = []
    skipped = []
    for key, value in updates.items():
        # 值必须是标量;key 限定为 PKGBUILD 变量名(字母数字下划线)
        if not isinstance(value, (str, int, float)) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            print(f"warning: 跳过非法更新项 {key}={value!r}", file=sys.stderr)
            continue
        if key == "pkgver" and pkgver_is_template:
            skipped.append(key)
            continue
        for i, line in enumerate(lines):
            if line.startswith(f"{key}="):
                lines[i] = f"{key}={value}\n"
                applied.append(key)
                break
        else:
            print(f"warning: PKGBUILD 中未找到变量 {key},跳过", file=sys.stderr)

    with open(pkgbuild_path, "w") as f:
        f.writelines(lines)

    if skipped:
        print(f"pkgver 为模板行,跳过整体替换(由派生变量生成)")
    print(f"已应用 {len(applied)} 个变量: {', '.join(applied) or '无'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
