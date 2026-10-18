#!/usr/bin/env python3
# build_skill.py — generates a self-contained SKILL.md from AGENTS.md + references/.
# build_skill.py — 根据 AGENTS.md 与 references/ 生成自包含的 SKILL.md。
#
# Why / 为什么：
#   Skill marketplaces (e.g. skills.sh) download ONLY SKILL.md. A thin forwarder
#   to AGENTS.md, or a bundle that still points at references/ and scripts/,
#   would ship a broken skill (missing files). So we inline the core guidance
#   AND every reference doc, and clearly flag that the helper scripts live in
#   the full repo (clone to run them). The result is one complete, tool-agnostic
#   file usable by any agent that loads SKILL.md.
#   技能市场（如 skills.sh）只下载 SKILL.md。指向 AGENTS.md 的薄转发器，或仍引用
#   references/、scripts/ 的副本，都会变成残缺技能（文件缺失）。因此我们把核心指引
#   与全部参考文档一并内联，并明确说明辅助脚本位于完整仓库（需 clone 才能运行）。
#   最终得到一份完整、与工具无关的文件，可被任何加载 SKILL.md 的智能体使用。
#
# Usage / 用法：
#   python scripts/python/build_skill.py
#
# AGENTS.md + references/ remain the single source of truth; SKILL.md is the
# generated, self-contained bundle. Re-run this after editing guidance.
# AGENTS.md 与 references/ 仍是唯一真源；SKILL.md 是生成的自包含副本。改完指引后重跑。

import os
import re
import sys

REPO_URL = "https://github.com/zero-labsco/zero-skills"


def read_version(root):
    """Read the kit version from the repo-root VERSION file (single source)."""
    path = os.path.join(root, "VERSION")
    if not os.path.exists(path):
        return "0.0.0"
    with open(path, "r", encoding="utf-8") as f:
        text = f.read().replace("\r\n", "\n").strip()
    return text.split("\n")[0].strip() or "0.0.0"


def self_check(out):
    """Return a list of self-containment problems in the bundled SKILL.md.

    Any literal `references/` or `scripts/` file path outside the two known
    explanatory notes is a defect, because the downloaded skill has neither
    folder.
    """
    problems = []
    for i, line in enumerate(out.split("\n"), start=1):
        if "Self-contained bundle" in line or "About the helper scripts" in line:
            continue
        if re.search(r"references/[A-Za-z0-9_./-]+\.[A-Za-z0-9]+", line):
            problems.append(f"Line {i}: dangling references/ path: {line}")
        if re.search(r"scripts/[A-Za-z0-9_./-]+\.(dart|py)", line):
            problems.append(f"Line {i}: dangling scripts/ path: {line}")
    return problems

DESCRIPTION = (
    "This skill provides general Flutter/Dart development guidance - "
    "implementing features, fixing bugs, managing pubspec dependencies and "
    "version constraints, following effective_dart, structuring lib/ "
    "(feature-first architecture, state management selection), writing "
    "platform channels for plugins across Android/iOS/Linux/macOS/Windows/Web/"
    "OpenHarmony, running flutter analyze/flutter test, and publishing to "
    "pub.dev. Use it for any Flutter or Dart project task."
)


def find_root(start, marker):
    d = start
    while not os.path.exists(os.path.join(d, marker)):
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent
    return d


def read_body(path):
    """Read *path*, normalize CRLF to LF, drop leading blanks and the first H1."""
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()
    lines = raw.replace("\r\n", "\n").split("\n")
    i = 0
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    if i < len(lines) and lines[i].startswith("# "):
        i += 1
    return "\n".join(lines[i:]).strip()


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = find_root(script_dir, "AGENTS.md")
    if root is None:
        sys.stderr.write("Could not locate AGENTS.md (repo root).\n")
        sys.exit(1)
    version = read_version(root)

    # --- Core guidance from AGENTS.md ---
    agents = read_body(os.path.join(root, "AGENTS.md"))
    paras = agents.split("\n\n")
    agents = "\n\n".join(
        p
        for p in paras
        if "single source of truth" not in p
        and "thin forwarder would ship an empty shell" not in p
    ).strip()
    agents = agents.replace(
        "See `references/platform_channel.md` for a full multi-platform template.",
        "See the **Plugin Platform Channel Reference** appendix below for a full "
        "multi-platform template.",
    )

    # --- Inline reference docs (so no references/ path is needed after download) ---
    refs = {
        "Plugin Platform Channel Reference":
            read_body(os.path.join(root, "references", "platform_channel.md")),
        "Application Architecture Reference":
            read_body(os.path.join(root, "references", "architecture.md")),
        "pubspec.yaml Reference":
            read_body(os.path.join(root, "references", "pubspec.md")),
        "Flutter / Dart Style Quick Reference":
            read_body(os.path.join(root, "references", "flutter_style.md")),
    }
    ref_sections = "\n\n".join(
        f"### {title}\n\n{body}" for title, body in refs.items()
    )

    out = (
        "---\n"
        "name: flutter-agent-skills\n"
        f"description: {DESCRIPTION}\n"
        f"version: {version}\n"
        "---\n"
        "\n"
        "# Flutter Agent Skills\n"
        "\n"
        f"> **Self-contained bundle (v{version}).** This `SKILL.md` is an "
        "auto-generated, complete copy\n"
        f"> of the guidance from [`AGENTS.md`]({REPO_URL}/blob/main/skills/flutter-agent-skills/AGENTS.md) "
        "and the docs\n"
        "> in `references/` (the canonical sources in this kit's repository "
        "root). It is\n"
        "> bundled so the skill works on its own even when a marketplace (e.g. "
        "skills.sh)\n"
        "> downloads only `SKILL.md`. The helper scripts (`scripts/`) are NOT "
        "included in\n"
        f"> this download — clone the repo at {REPO_URL} to run them.\n"
        ">\n"
        "> **Tool-agnostic.** This skill loads via `SKILL.md` in any agent that "
        "supports\n"
        "> the format — Claude Code, Cursor, Codex, GitHub Copilot, CodeBuddy, "
        "OpenCode,\n"
        "> Aider, and any other tool skills.sh or a compatible marketplace "
        "targets.\n"
        "> Follow the guidance below for any Flutter / Dart task regardless of "
        "which tool\n"
        "> you use.\n"
        "\n"
        "## Overview\n"
        "This skill activates for any Flutter / Dart project work. The guidance "
        "below is\n"
        "the tool-agnostic, bundled core: architecture, coding conventions, "
        "dependency\n"
        "and version rules, plugin platform-channel patterns, verification "
        "commands, and\n"
        "the deep-dive reference appendices.\n"
        "\n"
        "## General guidance (bundled from AGENTS.md)\n"
        "\n"
        f"{agents}\n"
        "\n"
        "> **About the helper scripts:** the `verify`, `create_feature`, "
        "`bump_version`,\n"
        "> and `build_skill` scripts mentioned above live in `scripts/` in the "
        "full\n"
        f"> repository at {REPO_URL}. This downloaded skill bundles the guidance "
        "only;\n"
        "> clone the repo to run the scripts.\n"
        "\n"
        "## Reference appendices\n"
        "\n"
        "The following deep-dive references are bundled inline so this skill is "
        "complete\n"
        "on its own — marketplaces such as skills.sh ship only `SKILL.md`.\n"
        "\n"
        f"{ref_sections}\n"
    )

    problems = self_check(out)
    if problems:
        sys.stderr.write("SKILL.md self-check FAILED:\n")
        for p in problems:
            sys.stderr.write(f"  - {p}\n")
        sys.exit(1)

    skill_path = os.path.join(root, "SKILL.md")
    with open(skill_path, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"Wrote {skill_path} (self-contained bundle v{version} from AGENTS.md + references/).")


if __name__ == "__main__":
    main()
