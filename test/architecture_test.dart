import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the feature-first layering rules from `STYLE_GUIDE.md`.
///
/// These are cheap text scans rather than a real dependency analyser, but they
/// catch the mistakes that actually happen: someone reaching for the Supabase
/// client inside a controller, or a domain file importing a generated row.
void main() {
  List<File> dartFilesUnder(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  List<String> featureNames() => Directory('lib/features')
      .listSync()
      .whereType<Directory>()
      .map((dir) => dir.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList();

  test('domain never imports Flutter, Supabase or generated rows', () {
    final violations = <String>[];

    for (final feature in featureNames()) {
      for (final file in dartFilesUnder('lib/features/$feature/domain')) {
        for (final line in file.readAsLinesSync()) {
          if (!line.startsWith('import ')) continue;
          final forbidden =
              line.contains('package:flutter') ||
              line.contains('package:supabase') ||
              line.contains('/models/') ||
              line.contains('/data/') ||
              line.contains('/presentation/');
          if (forbidden) violations.add('${file.path}: $line');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  /// Controllers that still reach Supabase directly. They are expected to be
  /// migrated to the events shape — data source + repository — as their UI is
  /// wired. `auth` owns the GoTrue session and has no table of its own to move
  /// behind a repository. Shrink this list; don't grow it otherwise.
  const unmigratedFeatures = {
    'auth',
    'chats',
    'circles',
    'friends',
    'invitations',
    'profile',
  };

  test('presentation never imports Supabase or the data layer', () {
    final violations = <String>[];

    for (final feature in featureNames()) {
      if (unmigratedFeatures.contains(feature)) continue;
      for (final file in dartFilesUnder('lib/features/$feature/presentation')) {
        for (final line in file.readAsLinesSync()) {
          if (!line.startsWith('import ')) continue;
          final forbidden =
              line.contains('package:supabase') ||
              line.contains('/data/') ||
              line.contains('/models/');
          if (forbidden) violations.add('${file.path}: $line');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('data never imports presentation', () {
    final violations = <String>[];

    for (final feature in featureNames()) {
      for (final file in dartFilesUnder('lib/features/$feature/data')) {
        for (final line in file.readAsLinesSync()) {
          if (line.startsWith('import ') && line.contains('/presentation/')) {
            violations.add('${file.path}: $line');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
