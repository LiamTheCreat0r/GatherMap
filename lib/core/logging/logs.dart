import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class Logs {
  Logs._();

  static bool _initialise = false;
  static final Logger _defaut = Logger('App');

  static void init() {
    if (_initialise) return;
    _initialise = true;

    Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
        '${record.time.toIso8601String()} '
        '[${record.level.name}] ${record.loggerName}: ${record.message}',
      );
      if (record.error != null) debugPrint('  error: ${record.error}');
      if (record.stackTrace != null) debugPrint('${record.stackTrace}');
    });
  }

  static Logger forClass(String nom) => Logger(nom);

  static void debug(String message) => _defaut.fine(message);
  static void info(String message) => _defaut.info(message);
  static void warning(String message, [Object? error, StackTrace? stack]) =>
      _defaut.warning(message, error, stack);
  static void error(String message, [Object? error, StackTrace? stack]) =>
      _defaut.severe(message, error, stack);
}