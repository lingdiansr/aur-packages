# AUR 包维护仓库

lingdiansr 维护的 AUR 包集合。单一 git 仓库统一管理全部包源码与自动化脚本,由 GitHub Actions 每日自动检查上游版本、构建验证并发布到 AUR;用户通过 AUR 安装时在本地自行构建。

## 包列表

| 包名 | 说明 | 版本检测 |
|---|---|---|
| [steamcommunity302](https://aur.archlinux.org/packages/steamcommunity302) | 羽翼城制作的 Steam/GitHub 反代加速工具(`s302` 启动) | dogfight360 博客(脚本解析) |
| [1panel-bin](https://aur.archlinux.org/packages/1panel-bin) | 1Panel 开源 Linux 服务器运维面板官方二进制 | 官方 CDN |
| [usbeam-hosts-editor](https://aur.archlinux.org/packages/usbeam-hosts-editor) | 羽翼城制作的 UsbEAm Hosts Editor(`uhe` 启动) | dogfight360 博客(脚本解析) |
| [jetbrains-lxgw-nerd-mono-ttf](https://aur.archlinux.org/packages/jetbrains-lxgw-nerd-mono-ttf) | JetBrains Mono + 霞鹜文楷合并 Nerd Font(2:1 CJK 比例) | GitHub tag |
| [vscode-config-helper-appimage](https://aur.archlinux.org/packages/vscode-config-helper-appimage) | VS Code C++ 配置器 AppImage | GitHub tag |
| [securelink](https://aur.archlinux.org/packages/securelink) | 网宿 SecureLink SDP/零信任客户端(Ubuntu GUI 版) | 手动更新(官网 WAF 无版本锚点) |

## 目录结构

```
.
├── <包名>/               # 每个包一个目录:PKGBUILD + .SRCINFO + install 等
├── scripts/
│   ├── check-<pkg>.sh    # 非 GitHub 源的版本检测脚本,输出更新变量 JSON
│   ├── update-version.sh # 改版本、重置 pkgrel、重算校验和、重生成 .SRCINFO
│   ├── apply-updates.py  # 将更新 JSON 的 key 应用到 PKGBUILD
│   └── publish.sh        # 推送包到 AUR(幂等,无差异自动跳过)
├── nvchecker.toml        # nvchecker 版本检测配置
├── old.json              # 各包已跟踪的版本(增量检测基准)
├── new.json              # nvchecker 运行产物(gitignore)
└── .github/workflows/
    ├── check-updates.yml # 每日检测 + 自动更新 + 发布
    └── publish-aur.yml   # PR 合并到 main 后发布
```

## 自动化更新流程

[check-updates.yml](.github/workflows/check-updates.yml) 每日 UTC 08:00 运行(也可手动触发),分三阶段:

1. **check** — `nvchecker` 对比 `old.json` 检测上游新版本。GitHub 源直接走 API;非 GitHub 源由 `scripts/check-<pkg>.sh` 解析(博客页面、Release asset 名、CDN)。
2. **update**(按包并行 matrix)— `update-version.sh` 修改 PKGBUILD(含派生变量)、重置 `pkgrel`、重算 sha256sum、重生成 .SRCINFO;随后 `makepkg` 构建验证;通过后发布到 AUR。artifact 只含包脚本(构建产物已清理,用户本地自行构建)。
3. **commit / pr** — 同步 `old.json` 并提交 main;或按模式开 PR。

### 运行模式

| 模式 | 行为 | 启用方式 |
|---|---|---|
| 直推(默认) | 检测到更新 → 构建 → 发布 AUR → 直接提交 main | 不设 `PR_MODE` |
| PR | 检测到更新 → 开 PR,review 合并后由 `publish-aur.yml` 发布 | 仓库变量 `PR_MODE=true`,或手动触发时勾选 `pr_mode` |

## 本地维护

```bash
# 检查某包是否有上游更新
nvchecker --file nvchecker.toml && nvcmp --file nvchecker.toml

# 手动更新一个包到指定版本(会重算校验和、重生成 .SRCINFO)
scripts/update-version.sh <包名> <新版本>

# 手动发布包到 AUR(需要 ~/.ssh 配置 aur 密钥与 git 身份)
scripts/publish.sh <包名>
```

`publish.sh` 幂等:与 AUR 无差异自动跳过;不在 AUR 上的包自动跳过。

## GitHub 配置

首次推送后需在仓库 Settings 配置:

**Secrets**(发布必需):
- `AUR_SSH_KEY` — AUR 账号注册的 SSH 私钥(AUR 要求专用密钥,勿与其他服务共用)
- `AUR_USER_NAME` / `AUR_USER_EMAIL` — 提交身份

**Variables**(可选):
- `PR_MODE` — `true` 时定时任务走 PR 模式

**Workflow 权限**:Settings → Actions → General → *Read and write permissions*(workflow 需推送 main、开 PR)。
