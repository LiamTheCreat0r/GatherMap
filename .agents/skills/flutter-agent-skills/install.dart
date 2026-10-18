#!/usr/bin/env dart
// install.dart — wires the flutter-agent-skills into the developer's AI tools.
// install.dart — 将 flutter-agent-skills 接入开发者的各类 AI 工具。
//
// Detects installed tools and places/soft-links the appropriate entry file so
// the kit's AGENTS.md (single source of truth) is consumed by each tool.
// 自动检测已安装的工具，并将合适的入口文件放置或软链过去，
// 让各工具都能读取本套件的 AGENTS.md（单一真相源）。
// Run with: `dart run install.dart`
// 运行方式：`dart run install.dart`
//
// Optional: pass a target project root so Cursor/Copilot entries are placed
// there directly, instead of scanning upward from the kit folder.
// 可选：传入目标项目根目录，让 Cursor/Copilot 入口直接写入该项目，
// 而不是从 kit 目录向上查找。
//   dart run install.dart --project /path/to/my_project
//   dart run install.dart /path/to/my_project
//   dart run install.dart -p /path/to/my_project -t cursor   # only Cursor
//   dart run install.dart -h                                  # show help
//
// All flags are optional; run with no args to wire every detected tool.
// 所有参数均可选；不带参数运行即接入所有已检测到的工具。
//
// Cross-platform (Windows / macOS / Linux). Idempotent: re-running is safe.
// 跨平台（Windows / macOS / Linux），且幂等：重复运行不会产生副作用。

import 'dart:io';
import 'dart:convert';

/// All tools the installer can wire, in display order.
/// 安装脚本支持接线的全部工具（展示顺序）。
const List<String> supportedTools = <String>[
  'codebuddy',
  'claude',
  'codex',
  'opencode',
  'cursor',
  'gemini',
  'copilot',
  'aider',
  'zed',
];

/// Human-readable labels for each supported tool (for the picker UI).
/// 每个支持工具的可读名称（用于选择界面）。
const Map<String, String> toolLabels = <String, String>{
  'codebuddy': 'CodeBuddy',
  'claude': 'Claude Code',
  'codex': 'Codex',
  'opencode': 'OpenCode',
  'cursor': 'Cursor',
  'gemini': 'Gemini CLI',
  'copilot': 'GitHub Copilot',
  'aider': 'Aider',
  'zed': 'Zed',
};

/// Tools that have no user-level skills dir and need a target project.
/// 没有用户级 skills 目录、需要指定目标项目的工具。
const Set<String> projectTools = <String>{
  'cursor',
  'gemini',
  'copilot',
  'aider',
  'zed',
};

/// Prefix marking a user-supplied "other" project-level instruction file.
/// The remainder is the target filename (e.g. `custom:CLAUDE.md`).
/// 标记用户自定义的「other」项目级指令文件的前缀；其后为文件名。
const String customPrefix = 'custom:';

/// Items shown per page in the interactive picker.
/// 交互选择界面每页展示的工具数量。
const int pageSize = 5;

/// Resolves the user-level skills base directory for a given tool.
/// 解析某工具的用户级 skills 根目录。
/// Returns null if the tool is not detected on this machine.
/// 若本机未检测到该工具则返回 null。
String? toolSkillsDir(String tool) {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE']; // Windows uses USERPROFILE
  // Windows 使用 USERPROFILE 作为主目录
  if (home == null) return null;

  switch (tool) {
    case 'codebuddy':
      // Windows: %USERPROFILE%\.codebuddy ; POSIX: ~/.codebuddy
      // 用户级 skills 目录：Windows 与类 Unix 路径一致。
      return pathJoin(home, ['.codebuddy', 'skills']);
    case 'claude':
      return pathJoin(home, ['.claude', 'skills']);
    case 'codex':
      // Honour CODEX_HOME override; else ~/.codex (Windows: %USERPROFILE%\.codex).
      // 支持 CODEX_HOME 覆盖；否则使用 ~/.codex（Windows 为 %USERPROFILE%\.codex）。
      final codexHome =
          Platform.environment['CODEX_HOME'] ?? pathJoin(home, ['.codex']);
      return pathJoin(codexHome, ['skills']);
    case 'opencode':
      // POSIX: ~/.config/opencode ; Windows: %USERPROFILE%\.config\opencode.
      // POSIX 为 ~/.config/opencode；Windows 为 %USERPROFILE%\.config\opencode。
      return pathJoin(home, ['.config', 'opencode', 'skills']);
    default:
      return null;
  }
}

/// Joins path segments with the platform separator.
/// 用平台分隔符拼接路径片段。
String pathJoin(String base, Iterable<String> parts) =>
    [base, ...parts].join(Platform.pathSeparator);

/// Soft-links (or copies, on platforms without link support) the kit folder
/// into the target tool's skills directory.
/// 将套件目录软链（或拷贝，于不支持软链的平台）到目标工具的 skills 目录。
void linkKitForTool(String tool, String skillsDir, String kitPath) {
  final target = Directory(pathJoin(skillsDir, ['flutter-agent-skills']));
  if (target.existsSync()) {
    print('[skip] $tool: ${target.path} already present');
    return;
  }
  Directory(skillsDir).createSync(recursive: true);
  try {
    // Use a symlink so updates are picked up without re-installing.
    // 使用软链，这样套件更新后无需重新安装即可生效。
    Link(target.path).createSync(kitPath);
    print('[link] $tool -> ${target.path}');
  } on FileSystemException {
    // Fallback: deep copy (Windows may block links without privileges).
    // 兜底：整目录拷贝（Windows 可能因权限不足而禁止创建软链）。
    _copyDir(Directory(kitPath), target);
    print('[copy] $tool -> ${target.path}');
  }
}

/// Copies AGENTS.md content into a project-level entry for tools that have no
/// user-level skills directory (Cursor / Copilot consume per-project files).
/// 将 AGENTS.md 内容拷贝到项目级入口，供没有用户级 skills 目录的工具使用
/// （Cursor / Copilot 读取的是项目级文件）。
void placeProjectEntry(String entryPath, File source) {
  final file = File(entryPath);
  if (file.existsSync()) {
    print('[skip] project entry already exists: $entryPath');
    return;
  }
  file.parent.createSync(recursive: true);
  source.copySync(entryPath);
  print('[copy] AGENTS.md -> $entryPath');
}

// Directories that must never be copied when falling back to a deep copy
// (otherwise the whole kit — including its .git history — would be duplicated).
const _skipDirs = {'.git', 'build', '.dart_tool', 'node_modules'};

void _copyDir(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync(recursive: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (_skipDirs.contains(name)) continue;
    if (entity is File) {
      entity.copySync('${to.path}${Platform.pathSeparator}$name');
    } else if (entity is Directory) {
      _copyDir(entity, Directory('${to.path}${Platform.pathSeparator}$name'));
    }
  }
}

/// Parses CLI args. Returns the explicitly passed project root (or null).
/// 解析命令行参数，返回显式传入的项目根目录（未传则返回 null）。
/// Accepts `--project <path>` or a bare positional `<path>`.
/// 支持 `--project <path>` 或裸位置参数 `<path>`。
String? parseProjectArg(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--project' || a == '-p') {
      if (i + 1 < args.length) return args[i + 1];
    } else if (a.startsWith('--project=')) {
      return a.split('=').last;
    } else if (!a.startsWith('-') && i == args.length - 1) {
      // A bare trailing path argument.
      // 末尾的裸路径参数。
      return a;
    }
  }
  return null;
}

/// Asks the user for a target project root to host project-level instruction
/// files (Cursor / Copilot / Gemini / Aider / Zed and any "other" custom file).
/// 让用户指定一个目标项目根目录，用于放置项目级指令文件
/// （Cursor / Copilot / Gemini / Aider / Zed 以及任意「other」自定义文件）。
///
/// Returns the absolute path if the user provides a valid, existing directory;
/// null if they skip (the installer then falls back to walking up from the kit).
/// 若用户提供的是存在且为目录的路径则返回绝对路径；若跳过则返回 null
/// （安装脚本随后回退为从 kit 目录向上查找）。
/// Non-interactive shells return null immediately. 非交互环境直接返回 null。
String? promptProjectRoot() {
  if (!stdin.hasTerminal) return null;
  stdout.writeln('');
  stdout.writeln(
    'Project-level entries (Cursor, Copilot, Gemini, Aider, Zed, other) '
    'need a target project.',
  );
  stdout.write(
    'Enter the project root path, or leave empty to auto-detect nearest '
    'Flutter project: ',
  );
  final raw = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
  if (raw.isEmpty) return null;
  final dir = Directory(raw);
  if (!dir.existsSync()) {
    stdout.writeln(
      '  [warn] "$raw" is not an existing directory — falling back to auto-detect.',
    );
    return null;
  }
  return dir.absolute.path;
}

/// Parses the optional `--tool` / `-t` filter (or null = wire all tools).
/// 解析可选的 `--tool` / `-t` 过滤（null 表示接入全部工具）。
/// Valid values: codebuddy, claude, codex, opencode, cursor, gemini, copilot.
/// 合法取值：codebuddy、claude、codex、opencode、cursor、gemini、copilot。
String? parseToolArg(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--tool' || a == '-t') {
      if (i + 1 < args.length) return args[i + 1].toLowerCase();
    } else if (a.startsWith('--tool=')) {
      return a.split('=').last.toLowerCase();
    }
  }
  return null;
}

/// Prints one page of the tool picker with selection state marked.
/// 打印工具选择界面的一页，并标记已选状态。
/// The trailing `[otherIdx]` entry lets the user name a custom project-level
/// instruction file for any tool not in the list.
/// 末尾的 `[otherIdx]` 项让用户为列表之外的工具指定自定义项目级指令文件。
void _printToolPage(int page, int totalPages, Set<String> selected, int otherIdx) {
  final start = page * pageSize;
  final end = (start + pageSize).clamp(0, supportedTools.length);
  stdout.writeln('');
  stdout.writeln('Select tools to wire (page ${page + 1}/$totalPages):');
  for (var i = start; i < end; i++) {
    final tool = supportedTools[i];
    final mark = selected.contains(tool) ? '*' : ' ';
    stdout.writeln(
      '  [${i + 1}] $mark ${toolLabels[tool] ?? tool}  ($tool)',
    );
  }
  // "other" entry — always on the last page, after the listed tools.
  // 「other」项 —— 始终在最后一页、已列出工具之后。
  if (page == totalPages - 1) {
    final mark = selected.any((t) => t.startsWith(customPrefix)) ? '*' : ' ';
    stdout.writeln(
      '  [$otherIdx] $mark other — name a custom project instruction file '
      '(e.g. CLAUDE.md, .windsurfrules)',
    );
  }
  stdout.writeln(
    '  Type a number then press Enter to toggle it. Multi-select: space/comma '
    'separated. o/other = custom file. n/p = next/prev page.',
  );
  stdout.writeln(
    '  Press Enter on an empty line to CONFIRM your selection (pick at least '
    'one first). q/quit/exit = quit. (Number keys + Enter — no arrow-key '
    'navigation; n/p to page.)',
  );
}

/// Interactive tool picker. Lists [supportedTools] in pages of [pageSize],
/// lets the user pick by number (multi-select, accumulates across pages), and
/// returns the chosen tool ids.
/// 交互式工具选择器：按 [pageSize] 分页列出支持的工具，用户按编号多选
/// （跨页累计），返回选中的工具 id 列表。
///
/// Non-interactive environments (no terminal, e.g. CI pipes) skip the prompt
/// and return every supported tool, so the installer never blocks.
/// 非交互环境（无终端，如 CI 管道）跳过提示并返回全部工具，避免阻塞。
List<String> promptToolSelection() {
  if (!stdin.hasTerminal) {
    stdout.writeln(
      '[info] Non-interactive shell detected — wiring all supported tools.',
    );
    return List<String>.from(supportedTools);
  }

  final selected = <String>{};
  final totalPages = (supportedTools.length / pageSize).ceil();
  final otherIdx = supportedTools.length + 1;
  var page = 0;
  while (true) {
    _printToolPage(page, totalPages, selected, otherIdx);
    stdout.write('> ');
    final raw = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
    // Empty line + Enter = confirm. Requires at least one selection.
    // 空行 + 回车 = 确认。要求至少已选一项，否则提示先选择。
    if (raw.isEmpty) {
      if (selected.isEmpty) {
        stdout.writeln(
          '  [hint] Pick at least one tool (type a number), or q to quit.',
        );
        continue;
      }
      return selected.toList();
    }
    if (raw == 'q' || raw == 'quit' || raw == 'exit') {
      stdout.writeln('  [info] Aborted — no changes made.');
      return <String>[];
    }
    if (raw == 'n' || raw == 'next') {
      page = (page + 1) % totalPages;
      continue;
    }
    if (raw == 'p' || raw == 'prev') {
      page = (page - 1 + totalPages) % totalPages;
      continue;
    }
    // "other" — let the user name a custom project-level instruction file.
    // 「other」——让用户指定自定义项目级指令文件名。
    if (raw == 'o' || raw == 'other' || raw == otherIdx.toString()) {
      stdout.write(
        '  Enter the target filename (e.g. CLAUDE.md, .windsurfrules, '
        'CONVENTIONS.md): ',
      );
      final fname = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
      final sane = fname.isNotEmpty &&
          !fname.contains('/') &&
          !fname.contains('\\') &&
          !fname.contains('..');
      if (sane) {
        selected.add('$customPrefix$fname');
        stdout.writeln('  [selected] custom:$fname  (Enter to confirm)');
      } else {
        stdout.writeln(
          '  [error] Invalid filename. Use a bare name (no path/separators).',
        );
      }
      continue;
    }
    final tokens = raw.split(RegExp(r'[,\s]+'));
    var ok = true;
    for (final t in tokens) {
      final idx = int.tryParse(t);
      // Numbers are per-page (1..pageSize); map to the global index.
      // 编号为「页内序号」（1..pageSize），映射到全局索引。
      final global = page * pageSize + (idx ?? 0) - 1;
      if (idx == null || idx < 1 || idx > pageSize || global < 0 || global >= supportedTools.length) {
        ok = false;
        break;
      }
      selected.add(supportedTools[global]);
    }
    if (ok) {
      stdout.writeln('  [selected] ${selected.join(', ')}  (Enter to confirm)');
    } else {
      stdout.writeln(
        '  [error] Invalid input. Use numbers 1-${supportedTools.length}, '
        'or n/p to page.',
      );
    }
  }
}

/// Prints the usage text and exits.
/// 打印用法说明并退出。
void printUsage() {
  print('''
Flutter Agent Kit installer — wires AGENTS.md into your AI tools.

Usage / 用法:
  dart run install.dart [options]

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
  dart run install.dart
  dart run install.dart -p /path/to/project
  dart run install.dart -p /path/to/project -t cursor
''');
}

void main(List<String> args) {
  // Show help and exit early (works in any shell: cmd / pwsh / bash).
  // 提前显示帮助并退出（在 cmd / pwsh / bash 等任意 shell 下均可用）。
  if (args.contains('-h') || args.contains('--help')) {
    printUsage();
    return;
  }

  final kitPath = Directory.current.absolute.path;
  final agentsFile = File('$kitPath${Platform.pathSeparator}AGENTS.md');
  if (!agentsFile.existsSync()) {
    stderr.writeln(
      'AGENTS.md not found in $kitPath. Run install.dart from '
      'the kit root.',
    );
    exit(1);
  }

  // Resolve the tool set to wire. An explicit -t narrows to one tool; otherwise
  // prompt interactively (or wire all in non-interactive shells).
  // 解析要接线的工具集合：显式 -t 缩小到单个工具；否则交互式选择
  // （非交互环境则全部接线）。
  final onlyTool = parseToolArg(args);
  final Set<String>? selectedTools = onlyTool != null
      ? <String>{onlyTool}
      : Set<String>.from(promptToolSelection());
  final wire = (String tool) =>
      selectedTools == null || selectedTools.contains(tool);

  // A target project is required for project-level entries. When the user ran
  // the interactive picker (or used an explicit -t for a project tool) without
  // passing --project, ask for the path so "other" / project files land in a
  // real project root. The -p / --project arg always wins if present.
  // 项目级入口需要一个目标项目。当用户在交互选择（或显式 -t 指定项目工具）
  // 而未传 --project 时，询问路径，让「other」/项目文件能落到真实项目根目录。
  // 若已传 -p / --project 则优先使用它。
  final projectArg = parseProjectArg(args);

  // 1. CodeBuddy — user-level skills symlink.
  // 1. CodeBuddy —— 用户级 skills 软链。
  if (wire('codebuddy')) {
    final cb = toolSkillsDir('codebuddy');
    if (cb != null) linkKitForTool('codebuddy', cb, kitPath);
  }

  // 2. Claude Code — user-level skills symlink.
  // 2. Claude Code —— 用户级 skills 软链。
  if (wire('claude')) {
    final cl = toolSkillsDir('claude');
    if (cl != null) linkKitForTool('claude', cl, kitPath);
  }

  // 2b. Codex — user-level skills symlink (honours $CODEX_HOME).
  // 2b. Codex —— 用户级 skills 软链（尊重 $CODEX_HOME）。
  if (wire('codex')) {
    final cx = toolSkillsDir('codex');
    if (cx != null) linkKitForTool('codex', cx, kitPath);
  }

  // 2c. OpenCode — user-level skills symlink (~/.config/opencode/skills).
  // 2c. OpenCode —— 用户级 skills 软链（~/.config/opencode/skills）。
  if (wire('opencode')) {
    final oc = toolSkillsDir('opencode');
    if (oc != null) linkKitForTool('opencode', oc, kitPath);
  }

  // 3. Cursor / Copilot / Gemini / Aider / Zed — no user-level concept; place
  // into a target project. Use an explicitly passed --project path if given;
  // otherwise walk up from the kit folder looking for a pubspec.yaml.
  // 3. Cursor / Copilot / Gemini / Aider / Zed —— 没有用户级概念，写入「目标
  // 项目」。若显式传入 --project 则用之；否则从 kit 目录向上查找 pubspec.yaml。
  final wantsProjectTool = selectedTools?.any(
        (t) => projectTools.contains(t) || t.startsWith(customPrefix),
      ) ??
      false;
  // Resolve the project root: explicit -p wins; then an interactive prompt
  // (if the user is in the picker flow and a project tool was chosen); then
  // auto-detect by walking up from the kit folder.
  // 解析项目根：显式 -p 优先；其次交互询问（picker 且选了项目工具时）；
  // 最后回退为从 kit 目录向上查找。
  String? projectRoot = projectArg != null
      ? Directory(projectArg).absolute.path
      : (wantsProjectTool ? promptProjectRoot() : null);
  projectRoot ??= _findProjectRoot(kitPath);
  if (projectRoot != null) {
    final sep = Platform.pathSeparator;
    for (final tool in selectedTools ?? const <String>[]) {
      if (tool.startsWith(customPrefix)) {
        // User-named custom project instruction file (from "other").
        // 用户通过「other」指定的自定义项目级指令文件。
        final fname = tool.substring(customPrefix.length);
        placeProjectEntry('$projectRoot$sep$fname', agentsFile);
      } else if (tool == 'cursor') {
        placeProjectEntry('$projectRoot$sep.cursorrules', agentsFile);
      } else if (tool == 'copilot') {
        placeProjectEntry(
          '$projectRoot$sep.github${sep}copilot-instructions.md',
          agentsFile,
        );
      } else if (tool == 'gemini') {
        placeProjectEntry('$projectRoot$sep.GEMINI.md', agentsFile);
      } else if (tool == 'aider') {
        placeProjectEntry('$projectRoot$sep.CONVENTIONS.md', agentsFile);
      } else if (tool == 'zed') {
        placeProjectEntry('$projectRoot$sep.rules', agentsFile);
      }
    }
  } else if (wantsProjectTool) {
    // These tools have no user-level skills dir — they need a target project.
    // Refuse to silently skip; tell the user exactly what to pass.
    // 这些工具没有用户级 skills 目录，需要指定目标项目。
    stderr.writeln(
      '[error] Cursor/Copilot/Gemini/Aider/Zed (and any "other" custom file) '
      'need a target Flutter project, but no --project was given and none was '
      'found by walking up from this kit.\n'
      '         Re-run with --project <path>, e.g.:\n'
      '           dart run install.dart -p /path/to/your_app${onlyTool != null ? ' -t $onlyTool' : ''}',
    );
    exit(1);
  }

  print('\nDone. Re-run anytime to update. See README.md for manual fallback.');
}

/// Walks up from [start] looking for a pubspec.yaml (a Flutter/Dart project).
/// 从 [start] 向上查找 pubspec.yaml（即 Flutter/Dart 项目根）。
String? _findProjectRoot(String start) {
  var dir = Directory(start);
  while (true) {
    if (File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null; // reached filesystem root
    dir = parent;
  }
}
