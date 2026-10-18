#!/usr/bin/env dart
// build_skill.dart — generates a self-contained SKILL.md from AGENTS.md + references/.
// build_skill.dart — 根据 AGENTS.md 与 references/ 生成自包含的 SKILL.md。
//
// Why / 为什么：
//   Skill marketplaces (e.g. skills.sh) download ONLY SKILL.md. A thin forwarder
//   to AGENTS.md, or a bundle that still points at references/ and scripts/,
//   would ship a broken skill (missing files). So we inline the core guidance
//   AND every reference doc, and clearly flag that the helper scripts live in
//   the full repo (clone to run them). The result is one complete, tool-agnostic
//   file usable by any agent that loads SKILL.md.
//   技能市场（如 skills.sh）只下载 SKILL.md。指向 AGENTS.md 的薄转发器，或仍引用
//   references/、scripts/ 的副本，都会变成残缺技能（文件缺失）。因此我们把核心指引
//   与全部参考文档一并内联，并明确说明辅助脚本位于完整仓库（需 clone 才能运行）。
//   最终得到一份完整、与工具无关的文件，可被任何加载 SKILL.md 的智能体使用。
//
// Usage / 用法：
//   dart run scripts/dart/build_skill.dart
//
// AGENTS.md + references/ remain the single source of truth; SKILL.md is the
// generated, self-contained bundle. Re-run this after editing guidance.
// AGENTS.md 与 references/ 仍是唯一真源；SKILL.md 是生成的自包含副本。改完指引后重跑。

import 'dart:convert';
import 'dart:io';

const _repoUrl = 'https://github.com/zero-labsco/zero-skills';

/// Reads the kit version from the repo-root VERSION file (single source for the
/// bundle version). Falls back to '0.0.0' if the file is missing.
String readVersion(String root) {
  final f = File('$root/VERSION');
  if (!f.existsSync()) return '0.0.0';
  return f
      .readAsStringSync(encoding: utf8)
      .replaceAll('\r\n', '\n')
      .trim()
      .split('\n')
      .first
      .trim();
}

/// Self-check: the bundled SKILL.md must be self-contained. Any literal
/// `references/` or `scripts/` path outside the allowed explanatory notes is a
/// defect (the downloaded skill has neither folder). Returns a list of problems.
List<String> selfCheck(String out) {
  final problems = <String>[];
  // Allowed prose that legitimately mentions these paths:
  //  - the top "Self-contained bundle" note (references/ in backticks, scripts/)
  //  - the "About the helper scripts" footer note
  // Anything else referencing references/ or scripts/ with a file path is bad.
  final lines = out.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // Skip the two known annotation blocks (they contain the bracketed URLs or
    // the "About the helper scripts" sentence).
    if (line.contains('Self-contained bundle') ||
        line.contains('About the helper scripts')) {
      continue;
    }
    if (line.contains('references/') &&
        RegExp(r'references/[A-Za-z0-9_./-]+\.[A-Za-z0-9]+').hasMatch(line)) {
      problems.add('Line ${i + 1}: dangling references/ path: $line');
    }
    if (line.contains('scripts/') &&
        RegExp(r'scripts/[A-Za-z0-9_./-]+\.(dart|py)').hasMatch(line)) {
      problems.add('Line ${i + 1}: dangling scripts/ path: $line');
    }
  }
  return problems;
}

const _description = 'This skill provides general Flutter/Dart development '
    'guidance - implementing features, fixing bugs, managing pubspec '
    'dependencies and version constraints, following effective_dart, '
    'structuring lib/ (feature-first architecture, state management selection), '
    'writing platform channels for plugins across Android/iOS/Linux/macOS/'
    'Windows/Web/OpenHarmony, running flutter analyze/flutter test, and '
    'publishing to pub.dev. Use it for any Flutter or Dart project task.';

/// Walks up from [start] until a directory containing [marker] is found.
String? findRoot(Directory start, String marker) {
  var dir = start;
  while (!File('${dir.path}/$marker').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
  return dir.path;
}

/// Reads [path], normalizes CRLF to LF, drops leading blank lines and the first
/// H1 title, and returns the trimmed markdown body.
String readBody(String path) {
  final raw = File(path).readAsStringSync(encoding: utf8);
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  var i = 0;
  while (i < lines.length && lines[i].trim().isEmpty) i++;
  if (i < lines.length && lines[i].startsWith('# ')) i++;
  return lines.sublist(i).join('\n').trim();
}

void main(List<String> args) {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final root = findRoot(scriptDir, 'AGENTS.md');
  if (root == null) {
    stderr.writeln('Could not locate AGENTS.md (repo root).');
    exit(1);
  }
  final version = readVersion(root);

  // --- Core guidance from AGENTS.md ---
  var agents = readBody('$root/AGENTS.md');
  // Drop two AGENTS.md-only paragraphs that are contradictory or irrelevant in a
  // downloaded skill: the "single source of truth" preamble, and the "Note on
  // SKILL.md" that tells contributors to edit AGENTS.md (which isn't present here).
  final paras = agents.split('\n\n');
  agents = paras
      .where((p) =>
          !p.contains('single source of truth') &&
          !p.contains('thin forwarder would ship an empty shell'))
      .join('\n\n')
      .trim();
  // The one dangling reference to a file we are about to inline as an appendix.
  agents = agents.replaceFirst(
    'See `references/platform_channel.md` for a full multi-platform template.',
    'See the **Plugin Platform Channel Reference** appendix below for a full '
        'multi-platform template.',
  );

  // --- Inline reference docs (so no references/ path is needed after download) ---
  final refs = <String, String>{
    'Plugin Platform Channel Reference':
        readBody('$root/references/platform_channel.md'),
    'Application Architecture Reference':
        readBody('$root/references/architecture.md'),
    'pubspec.yaml Reference': readBody('$root/references/pubspec.md'),
    'Flutter / Dart Style Quick Reference':
        readBody('$root/references/flutter_style.md'),
  };

  final refSections = refs.entries.map((e) {
    return '### ${e.key}\n\n${e.value}';
  }).join('\n\n');

  final out = '''
---
name: flutter-agent-skills
description: $_description
version: $version
---

# Flutter Agent Skills

> **Self-contained bundle (v$version).** This `SKILL.md` is an auto-generated, complete copy
> of the guidance from [`AGENTS.md`]($_repoUrl/blob/main/skills/flutter-agent-skills/AGENTS.md) and the docs
> in `references/` (the canonical sources in this kit's repository root). It is
> bundled so the skill works on its own even when a marketplace (e.g. skills.sh)
> downloads only `SKILL.md`. The helper scripts (`scripts/`) are NOT included in
> this download — clone the repo at $_repoUrl to run them.
>
> **Tool-agnostic.** This skill loads via `SKILL.md` in any agent that supports
> the format — Claude Code, Cursor, Codex, GitHub Copilot, CodeBuddy, OpenCode,
> Aider, and any other tool skills.sh or a compatible marketplace targets.
> Follow the guidance below for any Flutter / Dart task regardless of which tool
> you use.

## Overview
This skill activates for any Flutter / Dart project work. The guidance below is
the tool-agnostic, bundled core: architecture, coding conventions, dependency
and version rules, plugin platform-channel patterns, verification commands, and
the deep-dive reference appendices.

## General guidance (bundled from AGENTS.md)

$agents

> **About the helper scripts:** the `verify`, `create_feature`, `bump_version`,
> and `build_skill` scripts mentioned above live in `scripts/` in the full
> repository at $_repoUrl. This downloaded skill bundles the guidance only;
> clone the repo to run the scripts.

## Reference appendices

The following deep-dive references are bundled inline so this skill is complete
on its own — marketplaces such as skills.sh ship only `SKILL.md`.

$refSections
''';

  final problems = selfCheck(out);
  if (problems.isNotEmpty) {
    stderr.writeln('SKILL.md self-check FAILED:');
    for (final p in problems) stderr.writeln('  - $p');
    exit(1);
  }

  File('$root/SKILL.md').writeAsStringSync(out, encoding: utf8);
  print('Wrote $root/SKILL.md (self-contained bundle v$version from AGENTS.md + references/).');
}
