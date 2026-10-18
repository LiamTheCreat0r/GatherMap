<h1 align="center">Flutter Agent Kit</h1>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="许可：MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.3%2B-blue.svg" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.11%2B-0175C2.svg" alt="Dart"></a>
  <img src="https://img.shields.io/badge/AI-Agent-orange.svg" alt="AI 智能体">
  <img src="https://img.shields.io/badge/Skills-与工具无关-blueviolet.svg" alt="技能">
  <img src="https://img.shields.io/badge/工具-任意智能体(skills.sh)-ff69b4.svg" alt="支持工具">
</p>

<p align="center">
  一套与工具无关的 Flutter / Dart 开发指引套件。
</p>

<div align="center">

[English](./README.md) | **简体中文**

</div>

一套**与工具无关**的 Flutter / Dart 开发指引套件。它提供一份实质性指引——[`AGENTS.md`](./AGENTS.md)——作为**单一真相源**，外加**任意支持技能的智能体均可加载**的 [`SKILL.md`](./SKILL.md)（例如通过 skills.sh 安装）、[`references/`](./references) 下的参考文档，以及 Dart 辅助脚本。同一份 `AGENTS.md` 也能被偏好项目级指引的工具直接读取，因此内容只维护一处。

## ✨ 包含什么

| 文件 / 目录 | 作用 |
|------------|------|
| [`AGENTS.md`](./AGENTS.md) | **核心指引**——完整的、与工具无关的 Flutter / Dart 实践手册：编码规范、架构（应用与插件）、状态管理、依赖与版本、错误处理、路由、国际化、测试、异步/Stream、资源、序列化等。*单一真相源。* |
| [`SKILL.md`](./SKILL.md) | **与工具无关的**自动加载入口。它是 `AGENTS.md` 的**自包含副本**，由 `scripts/.../build_skill` 自动生成，以便技能在只下载 `SKILL.md` 的市场（如 skills.sh）上依然可用。 |
| [`references/`](./references) | 更深入的文档：[`flutter_style.md`](./references/flutter_style.md)、[`pubspec.md`](./references/pubspec.md)、[`architecture.md`](./references/architecture.md)、[`platform_channel.md`](./references/platform_channel.md)（覆盖 Android / iOS / Linux / macOS / Windows / Web / 鸿蒙）。 |
| [`scripts/dart/`](./scripts/dart) | Dart 辅助脚本（`*.dart`）。 |
| [`scripts/python/`](./scripts/python) | 同一组辅助脚本的 Python 版（`*.py`）。两者行为一致、CLI 相同：`verify`、`create_feature`、`bump_version`。 |
| [`install.dart`](./install.dart) / [`install.py`](./install.py) | 检测你使用的 AI 工具并把入口文件放到正确位置。Dart 或 Python 运行时任选其一。 |

## 🚀 安装（推荐）

按你已有的运行时选择——Dart SDK（任何 Flutter 开发者都已具备）或仅 Python 3。

```bash
git clone https://github.com/zero-labsco/zero-skills.git
cd skills/flutter-agent-skills
dart run install.dart      # Dart 运行时
# 或 / or
python install.py          # Python 运行时
```

`install.dart` / `install.py` 会检测已安装的工具并自动接入本套件。这覆盖了最常见的本地工具；若想获得市场支持的、持续增长的完整智能体列表，请改用 skills.sh 安装（见下文）。

| 工具 | 安装脚本的行为 |
|------|----------------------|
| **CodeBuddy** | 将本套件软链到 `~/.codebuddy/skills/flutter-agent-skills/`（通过 `SKILL.md` 自动加载）。 |
| **Claude Code** | 软链到 `~/.claude/skills/flutter-agent-skills/`（同样读取 `SKILL.md`）。 |
| **Codex** | 软链到 `$CODEX_HOME/skills/flutter-agent-skills/`（默认 `~/.codex/skills/`；读取 `SKILL.md`）。 |
| **OpenCode** | 软链到 `~/.config/opencode/skills/flutter-agent-skills/`（Windows：`%USERPROFILE%\.config\opencode\skills\`；读取 `SKILL.md`）。 |
| **Cursor** | 将 `AGENTS.md` 内容复制到项目的 `.cursorrules` / Cursor 规则。 |
| **Gemini CLI** | 将 `AGENTS.md` 复制到项目的 `GEMINI.md`（项目级上下文文件）。 |
| **Aider** | 将 `AGENTS.md` 复制到项目的 `CONVENTIONS.md`（Aider 的惯例文件）。 |
| **Zed** | 将 `AGENTS.md` 复制到项目的 `.rules`（Zed 的项目规则文件）。 |
| **GitHub Copilot**（VS Code） | 将 `AGENTS.md` 复制到当前项目的 `.github/copilot-instructions.md`。 |
| **other**（仅交互） | 为列表之外的工具指定自定义项目级指令文件（如 `CLAUDE.md`、`.windsurfrules`）。 |

> **本表的覆盖范围：** 这些是安装脚本能**自动为你接线**的工具（用户级软链或项目级文件）。套件本身与工具无关——任何其他支持 skills 的 agent 都可经由市场直接加载 `SKILL.md`（例如 `npx skills add https://skills.sh/...`）；该路径**不经过**本安装脚本，也不受上表影响。

随时可重跑安装脚本来更新（幂等）。

### 选项

| 参数 | 含义 | 是否可选 |
|------|------|----------|
| `-p, --project <path>` | Cursor/Copilot 入口写入的目标项目根目录。 | 可选（默认自动查找最近的 Flutter 项目） |
| `-t, --tool <tool>` | 只接入单个工具（非交互）：`codebuddy` \| `claude` \| `codex` \| `opencode` \| `cursor` \| `gemini` \| `copilot` \| `aider` \| `zed`。 | 可选（省略则进入交互清单；非交互环境自动接入全部） |
| `-h, --help` | 打印用法并退出。 | 可选 |

支持 **cmd**、**PowerShell**、**bash**、**zsh** —— 路径含空格时加引号即可，
如 `-p "D:\My Project\app"`。

### 指定目标项目（非侵入式）

在 kit 目录运行安装脚本，并通过 `--project` 传入目标项目根目录。Cursor / Copilot 的入口会**直接写入该项目**，而不会从 kit 目录向上查找——kit 目录本身不会被改动。

```bash
dart run install.dart -p /path/to/my_project
# 或 / or
python install.py -p /path/to/my_project
```

> 由于安装脚本本就在 kit 目录运行，`-p`（`--project` 的简写）是指定目标项目最简洁的方式。省略则回退到从 kit 目录向上查找最近的 Flutter 项目。

### 选择工具（交互清单）

**不带 `-t`** 运行时，安装脚本会显示交互清单，列出所有支持的工具，**每页 5 个**
（输入 `n` / `p` 翻页）。**输入编号后按回车**即可切换选中——支持多选，空格或逗号
分隔，跨页累计；选完后**在空行按回车确认**（至少需选一项，没有"全选"）。输入 `q` /
`quit` / `exit` 退出。（导航为「编号键 + 回车」，不支持方向键；`n`/`p` 翻页。）末尾的
**`other`** 项可让你为列表之外的工具
指定自定义项目级指令文件（如 `CLAUDE.md`、`.windsurfrules`）——它会像其他项目级
入口一样写入目标项目。当你选了某个项目级工具（Cursor / Copilot / Gemini / Aider /
Zed / other）却未传 `--project` 时，安装脚本会**询问目标项目根目录**，让文件落到
该项目；留空则自动查找最近的 Flutter 项目。在非交互环境（CI、管道输出）下会跳过
提示，自动接入所有支持的工具。

```bash
dart run install.dart            # 交互清单
python install.py               # 交互清单
```

### 只接入单个工具（非交互）

使用 `-t <tool>`（`--tool` 的简写）可跳过交互、只接入某一个工具。合法取值：
`codebuddy`、`claude`、`codex`、`opencode`、`cursor`、`gemini`、`copilot`、`aider`、`zed`。

```bash
dart run install.dart -p /path/to/my_project -t cursor
# 或 / or
python install.py -p /path/to/my_project --tool copilot
```

## 🛠 辅助脚本（Dart + Python）

辅助脚本各提供两份：Dart 版在 [`scripts/dart/`](./scripts/dart)，Python 版在 [`scripts/python/`](./scripts/python)。按你已有的运行时选择其一即可，CLI 与行为完全一致。

| 脚本 | Dart | Python | 用途 |
|------|------|--------|------|
| **校验** | `dart run scripts/dart/verify.dart [--no-publish]` | `python scripts/python/verify.py [--no-publish]` | 运行 `flutter analyze` + `flutter test` + 发布预检。 |
| **创建功能** | `dart run scripts/dart/create_feature.dart <name> [--pattern mvvm\|mvp]` | `python scripts/python/create_feature.py <name> [--pattern mvvm\|mvp]` | 生成 `lib/features/<name>/{data,domain,presentation/}`，含各层 barrel、默认 `presentation/view_model/`（MVVM）或 `presentation/presenter/`（MVP），以及 feature 级 barrel。 |
| **升级版本** | `dart run scripts/dart/bump_version.dart <major\|minor\|patch>` | `python scripts/python/bump_version.py <major\|minor\|patch>` | 升级 `pubspec.yaml` 并打印 git tag 命令。 |
| **构建技能** | `dart run scripts/dart/build_skill.dart` | `python scripts/python/build_skill.py` | 依据 `AGENTS.md` 重新生成自包含的 `SKILL.md` 副本（改完指引后运行）。 |

> **贡献提示:** `AGENTS.md` 与 `references/` 为唯一真源。修改后请重跑 `build_skill`
> 以保持打包的 `SKILL.md` 同步,请勿手动编辑 `SKILL.md`。
> **Contributing:** `AGENTS.md` + `references/` are the single source of truth.
> After editing either, re-run `build_skill` so the bundled `SKILL.md` stays in
> sync. Never hand-edit `SKILL.md`.

## 📦 安装（手动兜底）

安装脚本已**自动化**下面所有步骤，包括列表之外的任何工具——通过交互式的 **`other`** 选项（它会把 `AGENTS.md` 按你指定的文件名复制到项目里，例如 `CLAUDE.md`、`.windsurfrules`）。所以正常使用下你**不需要**这一节。

只有当脚本在你的环境里确实跑不起来时（不支持的系统、没有 Dart/Python 等），才回退到手动放置：

- **用户级 skills**（CodeBuddy / Claude Code / Codex / OpenCode）：把本文件夹复制到 `~/.codebuddy/skills/`、`~/.claude/skills/`、`~/.codex/skills/` 或 `~/.config/opencode/skills/`。
- **项目级入口**（Cursor / Copilot / Gemini / Aider / Zed / 任意「other」工具）：把 [`AGENTS.md`](./AGENTS.md) 复制到目标项目下、作为该工具的指令文件——`.cursorrules`、`.github/copilot-instructions.md`、`GEMINI.md`、`CONVENTIONS.md`、`.rules`，或你的智能体读取的任意文件。这正是脚本的 `other` 选项为你做的事。

多数用户更推荐**直接从市场安装**——例如 `npx skills add https://skills.sh/...`——它适用于任何支持技能的智能体，并直接拉取打包好的 `SKILL.md`。

## 🔄 更新

拉取最新代码后重跑 `dart run install.dart`（或 `python install.py`）。

## 📄 许可证

基于 [MIT 许可证](./LICENSE) 发布。
