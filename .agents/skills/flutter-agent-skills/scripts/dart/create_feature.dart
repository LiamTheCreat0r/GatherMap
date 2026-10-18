#!/usr/bin/env dart
// create_feature.dart — scaffolds a feature-first folder under lib/features.
// create_feature.dart — 在 lib/features 下生成「功能优先」结构的目录骨架。
//
// Usage / 用法:
//   dart run scripts/dart/create_feature.dart <feature_name> [--pattern mvvm|mvp]
// Example / 示例:
//   dart run scripts/dart/create_feature.dart auth
//   dart run scripts/dart/create_feature.dart auth --pattern mvp
// Creates / 生成:
//   lib/features/auth/{data,domain,presentation}/ with per-layer barrels, plus a
//   presentation/view_model (default MVVM) or presentation/presenter (MVP) layer,
//   and a feature-level barrel (auth.dart) re-exporting everything.
//   lib/features/auth/{data,domain,presentation}/ 及各层 barrel；presentation 下
//   默认生成 view_model（MVVM），或用 --pattern mvp 生成 presenter；feature 级
//   barrel（auth.dart）统一导出。

import 'dart:io';

const _usage = 'Usage: dart run scripts/dart/create_feature.dart '
    '<feature_name> [--pattern mvvm|mvp]';

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln(_usage);
    exit(1);
  }
  // Default pattern is MVVM (per the kit's recommended default).
  // 默认模式为 MVVM（与 kit 的默认推荐一致）。
  var pattern = 'mvvm';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--pattern' && i + 1 < args.length) {
      pattern = args[i + 1].toLowerCase();
    } else if (args[i].startsWith('--pattern=')) {
      pattern = args[i].split('=').last.toLowerCase();
    }
  }
  if (pattern != 'mvvm' && pattern != 'mvp') {
    stderr.writeln('Unknown pattern "$pattern". Use mvvm or mvp.');
    exit(1);
  }

  final name = positional.first.trim();
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    stderr.writeln('Feature name must be snake_case starting with a letter.');
    exit(1);
  }

  final sep = Platform.pathSeparator;
  final base = '${Directory.current.absolute.path}$sep'
      'lib${sep}features${sep}$name';

  void mkdir(String rel) =>
      Directory('$base$sep$rel').createSync(recursive: true);

  void barrel(String rel, String fileName, String comment) {
    File('$base$sep$rel$sep$fileName')
      ..createSync()
      ..writeAsStringSync('// $comment\n');
  }

  for (final layer in ['data', 'domain', 'presentation']) {
    mkdir(layer);
    barrel(layer, '${name}_$layer.dart', '$name $layer layer');
  }

  // Presentation sub-layer for the chosen architecture.
  // presentation 下的架构子层。
  final sub = pattern == 'mvvm' ? 'view_model' : 'presenter';
  final subFile = pattern == 'mvvm'
      ? '${name}_view_model.dart'
      : '${name}_presenter.dart';
  mkdir('presentation$sep$sub');
  barrel('presentation$sep$sub', subFile,
      '$name $pattern ${pattern == 'mvvm' ? 'ViewModel' : 'Presenter'}');

  // Feature-level barrel re-exporting layers + the architecture sub-layer.
  // feature 级 barrel，统一导出各层与架构子层。
  File('$base$sep$name.dart')
    ..createSync()
    ..writeAsStringSync(
      'export \'$name/data/${name}_data.dart\';\n'
      'export \'$name/domain/${name}_domain.dart\';\n'
      'export \'$name/presentation/${name}_presentation.dart\';\n'
      'export \'$name/presentation/$sub/$subFile\';\n',
    );

  print('Created feature "$name" at lib/features/$name '
      '(pattern: $pattern)');
}
