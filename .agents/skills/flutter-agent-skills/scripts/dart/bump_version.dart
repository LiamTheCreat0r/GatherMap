#!/usr/bin/env dart
// bump_version.dart — bumps the version in pubspec.yaml per semver.
// bump_version.dart — 按语义化版本号（semver）递增 pubspec.yaml 中的版本。
//
// Usage:  dart run scripts/dart/bump_version.dart <major|minor|patch>
// 用法：  dart run scripts/dart/bump_version.dart <major|minor|patch>
// Reads the current `version:` line, increments the chosen segment, writes it
// back, and prints the suggested git tag command. Does not run git itself.
// 读取当前 `version:` 行，递增所选分段并写回，同时打印建议的 git tag 命令（不自动执行 git）。

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run scripts/bump_version.dart <major|minor|patch>',
    );
    exit(1);
  }
  final kind = args.first;
  if (!['major', 'minor', 'patch'].contains(kind)) {
    stderr.writeln('Kind must be one of: major, minor, patch.');
    exit(1);
  }

  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('pubspec.yaml not found in the current directory.');
    exit(1);
  }
  final lines = file.readAsLinesSync();
  final idx = lines.indexWhere((l) => l.startsWith('version:'));
  if (idx < 0) {
    stderr.writeln('No "version:" field found in pubspec.yaml.');
    exit(1);
  }

  final m = RegExp(
    r'version:\s*(\d+)\.(\d+)\.(\d+)(.*)',
  ).firstMatch(lines[idx]);
  if (m == null) {
    stderr.writeln('Could not parse the version string: "${lines[idx]}".');
    exit(1);
  }
  var major = int.parse(m.group(1)!);
  var minor = int.parse(m.group(2)!);
  var patch = int.parse(m.group(3)!);
  final suffix = m.group(4) ?? '';

  switch (kind) {
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      break;
    case 'patch':
      patch += 1;
      break;
  }

  final newVersion = '$major.$minor.$patch$suffix';
  lines[idx] = 'version: $newVersion';
  // Preserve the file's original line endings (CRLF on Windows) so re-running
  // does not rewrite the whole file and cause spurious VCS diffs.
  final original = file.readAsStringSync();
  final newline = original.contains('\r\n') ? '\r\n' : '\n';
  file.writeAsStringSync(lines.join(newline));

  print('Bumped version to $newVersion');
  print('Next steps:');
  print('  git add pubspec.yaml');
  print('  git commit -m "chore: bump version to $newVersion"');
  print('  git tag v$newVersion && git push origin v$newVersion');
}
