#!/usr/bin/env python3
"""install.py — wires the flutter-agent-skills into the developer's AI tools.
install.py — 将 flutter-agent-skills 接入开发者的各类 AI 工具。

Detect installed tools and place/soft-link the appropriate entry file so the
kit's AGENTS.md (single source of truth) is consumed by each tool.
自动检测已安装的工具，并将合适的入口文件放置或软链过去，
让各工具都能读取本套件的 AGENTS.md（单一真相源）。

Run with:  python install.py
运行方式：  python install.py

Optional: pass a target project root so Cursor/Copilot entries are placed
there directly, instead of scanning upward from the kit folder.
可选：传入目标项目根目录，让 Cursor/Copilot 入口直接写入该项目，
而不是从 kit 目录向上查找。
  python install.py --project /path/to/my_project
  python install.py /path/to/my_project
  python install.py -p /path/to/my_project -t cursor   # only Cursor
  python install.py -h                                  # show help

All flags are optional; run with no args to wire every detected tool.
所有参数均可选；不带参数运行即接入所有已检测到的工具。

Cross-platform (Windows / macOS / Linux). Idempotent: re-running is safe.
跨平台（Windows / macOS / Linux），且幂等：重复运行不会产生副作用。
"""

import os
import re
import shutil
import sys

KIT_NAME = "flutter-agent-skills"

# All tools the installer can wire, in display order.
# 安装脚本支持接线的全部工具（展示顺序）。
SUPPORTED_TOOLS = [
    "codebuddy", "claude", "codex", "opencode", "cursor", "gemini", "copilot",
    "aider", "zed",
]

# Human-readable labels for each supported tool (for the picker UI).
# 每个支持工具的可读名称（用于选择界面）。
TOOL_LABELS = {
    "codebuddy": "CodeBuddy",
    "claude": "Claude Code",
    "codex": "Codex",
    "opencode": "OpenCode",
    "cursor": "Cursor",
    "gemini": "Gemini CLI",
    "copilot": "GitHub Copilot",
    "aider": "Aider",
    "zed": "Zed",
}

# Tools that have no user-level skills dir and need a target project.
# 没有用户级 skills 目录、需要指定目标项目的工具。
PROJECT_TOOLS = {"cursor", "gemini", "copilot", "aider", "zed"}

# Prefix marking a user-supplied "other" project-level instruction file.
# The remainder is the target filename (e.g. "custom:CLAUDE.md").
# 标记用户自定义的「other」项目级指令文件的前缀；其后为文件名。
CUSTOM_PREFIX = "custom:"

# Items shown per page in the interactive picker.
# 交互选择界面每页展示的工具数量。
PAGE_SIZE = 5


def tool_skills_dir(tool):
    """Resolve the user-level skills base directory for a given tool.
    解析某工具的用户级 skills 根目录。

    Returns None if the tool is not detected on this machine.
    若本机未检测到该工具则返回 None。
    """
    # Windows uses USERPROFILE; POSIX uses HOME. / Windows 用 USERPROFILE，类 Unix 用 HOME。
    home = os.environ.get("HOME") or os.environ.get("USERPROFILE")
    if home is None:
        return None

    if tool == "codebuddy":
        # Windows: %USERPROFILE%\.codebuddy ; POSIX: ~/.codebuddy
        # 用户级 skills 目录：Windows 与类 Unix 路径一致。
        return os.path.join(home, ".codebuddy", "skills")
    if tool == "claude":
        return os.path.join(home, ".claude", "skills")
    if tool == "codex":
        # Honour CODEX_HOME override; else ~/.codex (Windows: %USERPROFILE%\.codex).
        # 支持 CODEX_HOME 覆盖；否则使用 ~/.codex（Windows 为 %USERPROFILE%\.codex）。
        codex_home = os.environ.get("CODEX_HOME") or os.path.join(home, ".codex")
        return os.path.join(codex_home, "skills")
    if tool == "opencode":
        # POSIX: ~/.config/opencode ; Windows: %USERPROFILE%\.config\opencode.
        # POSIX 为 ~/.config/opencode；Windows 为 %USERPROFILE%\.config\opencode。
        return os.path.join(home, ".config", "opencode", "skills")
    return None


def link_kit_for_tool(tool, skills_dir, kit_path):
    """Soft-link (or copy, on platforms without link support) the kit folder
    into the target tool's skills directory.
    将套件目录软链（或拷贝，于不支持软链的平台）到目标工具的 skills 目录。
    """
    target = os.path.join(skills_dir, KIT_NAME)
    if os.path.exists(target):
        print(f"[skip] {tool}: {target} already present")
        return
    os.makedirs(skills_dir, exist_ok=True)
    try:
        # Use a symlink so updates are picked up without re-installing.
        # 使用软链，这样套件更新后无需重新安装即可生效。
        os.symlink(kit_path, target)
        print(f"[link] {tool} -> {target}")
    except OSError:
        # Fallback: deep copy (Windows may block links without privileges).
        # 兜底：整目录拷贝（Windows 可能因权限不足而禁止创建软链）。
        shutil.copytree(kit_path, target)
        print(f"[copy] {tool} -> {target}")


def place_project_entry(entry_path, source):
    """Copy AGENTS.md content into a project-level entry for tools that have no
    user-level skills directory (Cursor / Copilot consume per-project files).
    将 AGENTS.md 内容拷贝到项目级入口，供没有用户级 skills 目录的工具使用
    （Cursor / Copilot 读取的是项目级文件）。
    """
    if os.path.exists(entry_path):
        print(f"[skip] project entry already exists: {entry_path}")
        return
    os.makedirs(os.path.dirname(entry_path), exist_ok=True)
    shutil.copyfile(source, entry_path)
    print(f"[copy] AGENTS.md -> {entry_path}")


def find_project_root(start):
    """Walk up from [start] looking for a pubspec.yaml (a Flutter/Dart project).
    从 start 向上查找 pubspec.yaml（即 Flutter/Dart 项目根）。
    """
    dir_ = start
    while True:
        if os.path.exists(os.path.join(dir_, "pubspec.yaml")):
            return dir_
        parent = os.path.dirname(dir_)
        if parent == dir_:  # reached filesystem root / 到达文件系统根
            return None
        dir_ = parent


def parse_project_arg(argv):
    """Parse the optional target project root from CLI args (or None).
    解析命令行中可选的目标项目根目录（未传则返回 None）。

    Accepts `--project <path>` or a bare positional `<path>`.
    支持 `--project <path>` 或裸位置参数 `<path>`。
    """
    for i, a in enumerate(argv):
        if a in ("--project", "-p"):
            if i + 1 < len(argv):
                return argv[i + 1]
        elif a.startswith("--project="):
            return a.split("=", 1)[1]
        elif not a.startswith("-") and i == len(argv) - 1:
            # A bare trailing path argument. / 末尾的裸路径参数。
            return a
    return None


def parse_tool_arg(argv):
    """Parse the optional `--tool` / `-t` filter (or None = wire all tools).
    解析可选的 `--tool` / `-t` 过滤（None 表示接入全部工具）。

    Valid values: codebuddy, claude, codex, opencode, cursor, gemini, copilot.
    合法取值：codebuddy、claude、codex、opencode、cursor、gemini、copilot。
    """
    for i, a in enumerate(argv):
        if a in ("--tool", "-t"):
            if i + 1 < len(argv):
                return argv[i + 1].lower()
        elif a.startswith("--tool="):
            return a.split("=", 1)[1].lower()
    return None


def _print_tool_page(page, total_pages, selected, other_idx):
    """Print one page of the tool picker with selection state marked.
    打印工具选择界面的一页，并标记已选状态。
    The trailing [other_idx] entry lets the user name a custom project-level
    instruction file for any tool not in the list.
    末尾的 [other_idx] 项让用户为列表之外的工具指定自定义项目级指令文件。
    """
    start = page * PAGE_SIZE
    end = min(start + PAGE_SIZE, len(SUPPORTED_TOOLS))
    print("")
    print(f"Select tools to wire (page {page + 1}/{total_pages}):")
    for i in range(start, end):
        tool = SUPPORTED_TOOLS[i]
        mark = "*" if tool in selected else " "
        print(f"  [{i + 1}] {mark} {TOOL_LABELS.get(tool, tool)}  ({tool})")
    # "other" entry — always on the last page, after the listed tools.
    # 「other」项 —— 始终在最后一页、已列出工具之后。
    if page == total_pages - 1:
        mark = "*" if any(t.startswith(CUSTOM_PREFIX) for t in selected) else " "
        print(
            f"  [{other_idx}] {mark} other — name a custom project instruction "
            "file (e.g. CLAUDE.md, .windsurfrules)"
        )
    print(
        "  Type a number then press Enter to toggle it. Multi-select: space/comma "
        "separated. o/other = custom file. n/p = next/prev page."
    )
    print(
        "  Press Enter on an empty line to CONFIRM your selection (pick at least "
        "one first). q/quit/exit = quit. (Number keys + Enter — no arrow-key "
        "navigation; n/p to page.)"
    )


def prompt_tool_selection():
    """Interactive tool picker. Lists SUPPORTED_TOOLS in pages of PAGE_SIZE,
    lets the user pick by number (multi-select, accumul across pages), and
    returns the chosen tool ids (custom files are prefixed with CUSTOM_PREFIX).
    交互式工具选择器：按 PAGE_SIZE 分页列出支持的工具，用户按编号多选
    （跨页累计），返回选中的工具 id 列表（自定义文件以 CUSTOM_PREFIX 前缀）。

    Non-interactive environments (no terminal, e.g. CI pipes) skip the prompt
    and return every supported tool, so the installer never blocks.
    非交互环境（无终端，如 CI 管道）跳过提示并返回全部工具，避免阻塞。
    """
    if not sys.stdin.isatty():
        print(
            "[info] Non-interactive shell detected — wiring all supported tools."
        )
        return list(SUPPORTED_TOOLS)

    selected = set()
    total_pages = (len(SUPPORTED_TOOLS) + PAGE_SIZE - 1) // PAGE_SIZE
    other_idx = len(SUPPORTED_TOOLS) + 1
    page = 0
    while True:
        _print_tool_page(page, total_pages, selected, other_idx)
        try:
            raw = input("> ").strip()
        except EOFError:
            raw = ""
        # Empty line + Enter = confirm. Requires at least one selection.
        # 空行 + 回车 = 确认。要求至少已选一项，否则提示先选择。
        if raw == "":
            if not selected:
                print(
                    "  [hint] Pick at least one tool (type a number), or q to quit."
                )
                continue
            return list(selected)
        if raw in ("q", "quit", "exit"):
            print("  [info] Aborted — no changes made.")
            return []
        if raw in ("n", "next"):
            page = (page + 1) % total_pages
            continue
        if raw in ("p", "prev"):
            page = (page - 1 + total_pages) % total_pages
            continue
        # "other" — let the user name a custom project-level instruction file.
        # 「other」——让用户指定自定义项目级指令文件名。
        if raw in ("o", "other", str(other_idx)):
            fname = input(
                "  Enter the target filename (e.g. CLAUDE.md, .windsurfrules, "
                "CONVENTIONS.md): "
            ).strip()
            sane = (
                fname
                and "/" not in fname
                and "\\" not in fname
                and ".." not in fname
            )
            if sane:
                selected.add(f"{CUSTOM_PREFIX}{fname}")
                print(f"  [selected] custom:{fname}  (Enter to confirm)")
            else:
                print(
                    "  [error] Invalid filename. Use a bare name "
                    "(no path/separators)."
                )
            continue
        tokens = [t for t in re.split(r"[,\s]+", raw) if t]
        ok = True
        for t in tokens:
            try:
                idx = int(t)
            except ValueError:
                idx = -1
            # Numbers are per-page (1..PAGE_SIZE); map to the global index.
            # 编号为「页内序号」（1..PAGE_SIZE），映射到全局索引。
            global_idx = page * PAGE_SIZE + idx - 1
            if idx < 1 or idx > PAGE_SIZE or global_idx < 0 or global_idx >= len(SUPPORTED_TOOLS):
                ok = False
                break
            selected.add(SUPPORTED_TOOLS[global_idx])
        if ok:
            print(f"  [selected] {', '.join(selected)}  (Enter to confirm)")
        else:
            print(
                f"  [error] Invalid input. Use numbers 1-{len(SUPPORTED_TOOLS)}, "
                "or n/p to page."
            )


def prompt_project_root():
    """Ask the user for a target project root to host project-level instruction
    files (Cursor / Copilot / Gemini / Aider / Zed and any "other" custom file).
    让用户指定一个目标项目根目录，用于放置项目级指令文件
    （Cursor / Copilot / Gemini / Aider / Zed 以及任意「other」自定义文件）。

    Returns the absolute path if the user provides a valid, existing directory;
    None if they skip (the installer then falls back to walking up from the kit).
    若用户提供的是存在且为目录的路径则返回绝对路径；若跳过则返回 None
    （安装脚本随后回退为从 kit 目录向上查找）。
    Non-interactive shells return None immediately. / 非交互环境直接返回 None。
    """
    if not sys.stdin.isatty():
        return None
    print("")
    print(
        "Project-level entries (Cursor, Copilot, Gemini, Aider, Zed, other) "
        "need a target project."
    )
    raw = input(
        "Enter the project root path, or leave empty to auto-detect nearest "
        "Flutter project: "
    ).strip()
    if not raw:
        return None
    if not os.path.isdir(raw):
        print(
            f'  [warn] "{raw}" is not an existing directory — falling back to '
            "auto-detect."
        )
        return None
    return os.path.abspath(raw)


def print_usage():
    """Print the usage text. 打印用法说明。"""
    print(
        """
Flutter Agent Kit installer — wires AGENTS.md into your AI tools.

Usage / 用法:
  python install.py [options]

Options / 选项:
  -p, --project <path>   Target project root for Cursor/Gemini/Copilot entries.
                         Cursor/Gemini/Copilot 入口写入的目标项目根目录。
  -t, --tool <tool>      Wire only one tool (non-interactive):
                         codebuddy|claude|codex|opencode|cursor|gemini|copilot.
                         只接入单个工具（非交互模式；省略则列出清单供选择）。
  -h, --help             Show this help and exit. 显示帮助并退出。

With no -t, the installer shows an interactive list (5 per page) to pick
tools; in non-interactive shells it wires all supported tools.
不带 -t 时，安装脚本会显示交互清单（每页 5 个）供你选择；
在非交互环境中则自动接入所有支持的工具。

Examples / 示例:
  python install.py
  python install.py -p /path/to/project
  python install.py -p /path/to/project -t cursor
"""
    )


def main(argv):
    """Wire the kit into detected AI tools based on CLI flags.
    根据命令行参数将套件接入已检测到的 AI 工具。

    Flags: -p/--project <path>, -t/--tool <tool>, -h/--help.
    参数：-p/--project <path>、-t/--tool <tool>、-h/--help。
    """
    # Show help and exit early (works in any shell: cmd / pwsh / bash).
    # 提前显示帮助并退出（在 cmd / pwsh / bash 等任意 shell 下均可用）。
    if "-h" in argv or "--help" in argv:
        print_usage()
        return 0

    kit_path = os.path.abspath(os.getcwd())
    agents_file = os.path.join(kit_path, "AGENTS.md")
    if not os.path.exists(agents_file):
        sys.stderr.write(
            f"AGENTS.md not found in {kit_path}. Run install.py from the kit root.\n"
        )
        return 1

    # Resolve the tool set to wire. An explicit -t narrows to one tool; otherwise
    # prompt interactively (or wire all in non-interactive shells).
    # 解析要接线的工具集合：显式 -t 缩小到单个工具；否则交互式选择
    # （非交互环境则全部接线）。
    only_tool = parse_tool_arg(argv)
    selected_tools = {only_tool} if only_tool is not None else set(prompt_tool_selection())

    def wire(tool):
        """True if [tool] should be wired (in the selected set)."""
        return tool in selected_tools

    # A target project is required for project-level entries. When the user ran
    # the interactive picker (or used an explicit -t for a project tool) without
    # passing --project, ask for the path so "other" / project files land in a
    # real project root. The -p / --project arg always wins if present.
    # 项目级入口需要一个目标项目。当用户在交互选择（或显式 -t 指定项目工具）
    # 而未传 --project 时，询问路径，让「other」/项目文件能落到真实项目根目录。
    # 若已传 -p / --project 则优先使用它。
    project_arg = parse_project_arg(argv)

    # 1. CodeBuddy — user-level skills symlink.
    # 1. CodeBuddy —— 用户级 skills 软链。
    if wire("codebuddy"):
        cb = tool_skills_dir("codebuddy")
        if cb is not None:
            link_kit_for_tool("codebuddy", cb, kit_path)

    # 2. Claude Code — user-level skills symlink.
    # 2. Claude Code —— 用户级 skills 软链。
    if wire("claude"):
        cl = tool_skills_dir("claude")
        if cl is not None:
            link_kit_for_tool("claude", cl, kit_path)

    # 2b. Codex — user-level skills symlink (honours $CODEX_HOME).
    # 2b. Codex —— 用户级 skills 软链（尊重 $CODEX_HOME）。
    if wire("codex"):
        cx = tool_skills_dir("codex")
        if cx is not None:
            link_kit_for_tool("codex", cx, kit_path)

    # 2c. OpenCode — user-level skills symlink (~/.config/opencode/skills).
    # 2c. OpenCode —— 用户级 skills 软链（~/.config/opencode/skills）。
    if wire("opencode"):
        oc = tool_skills_dir("opencode")
        if oc is not None:
            link_kit_for_tool("opencode", oc, kit_path)

    # 3. Cursor / Copilot / Gemini — no user-level concept; place into a target
    # project. Use an explicitly passed --project path if given; then ask
    # interactively (if the user is in the picker flow and chose a project tool);
    # otherwise walk up from the kit folder looking for a pubspec.yaml.
    # 3. Cursor / Copilot / Gemini —— 没有用户级概念，写入「目标项目」。
    # 若显式传入 --project 则用之；其次交互询问（picker 且选了项目工具时）；
    # 最后回退为从 kit 目录向上查找 pubspec.yaml。
    wants_project_tool = bool(selected_tools & PROJECT_TOOLS) or any(
        t.startswith(CUSTOM_PREFIX) for t in selected_tools
    )
    project_root = (
        os.path.abspath(project_arg)
        if project_arg is not None
        else (prompt_project_root() if wants_project_tool else None)
    )
    if project_root is None:
        project_root = find_project_root(kit_path)
    if project_root is not None:
        for tool in selected_tools:
            if tool.startswith(CUSTOM_PREFIX):
                # User-named custom project instruction file (from "other").
                # 用户通过「other」指定的自定义项目级指令文件。
                fname = tool[len(CUSTOM_PREFIX):]
                place_project_entry(os.path.join(project_root, fname), agents_file)
            elif tool == "cursor":
                place_project_entry(os.path.join(project_root, ".cursorrules"), agents_file)
            elif tool == "copilot":
                place_project_entry(
                    os.path.join(project_root, ".github", "copilot-instructions.md"),
                    agents_file,
                )
            elif tool == "gemini":
                place_project_entry(os.path.join(project_root, "GEMINI.md"), agents_file)
            elif tool == "aider":
                place_project_entry(os.path.join(project_root, "CONVENTIONS.md"), agents_file)
            elif tool == "zed":
                place_project_entry(os.path.join(project_root, ".rules"), agents_file)
    elif selected_tools & PROJECT_TOOLS or any(t.startswith(CUSTOM_PREFIX) for t in selected_tools):
        print(
            "[info] No target project resolved (no --project arg and no "
            "Flutter project found above this kit). Re-run with --project "
            "<path> to wire Cursor/Gemini/Copilot/Aider/Zed (or any other "
            "custom file)."
        )

    print("\nDone. Re-run anytime to update. See README.md for manual fallback.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
