import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Lifecycle shared by every controller in `lib/controllers/`.
///
/// [ControllerStatus.idle] → [ControllerStatus.loading] →
/// [ControllerStatus.ready] or [ControllerStatus.error].
enum ControllerStatus { idle, loading, ready, error }

/// Base class for the controllers that sit between the generated models in
/// `lib/models/` and the views in `lib/views/`.
///
/// A controller owns the state of one table: it runs queries through
/// [client], keeps the result in fields exposed by getters, and reports
/// [status]/[error] so views can render loading and failure states.
///
/// Subclasses implement the queries and call [runAction] (fire-and-forget
/// writes) or [runQuery] (reads that return a row or a list). All state
/// changes are announced with [notifySafely], which stays quiet after
/// [dispose].
abstract class BaseController extends ChangeNotifier {
  BaseController({SupabaseService? service})
    : _service = service ?? SupabaseService();

  final SupabaseService _service;

  ControllerStatus _status = ControllerStatus.idle;
  String? _error;
  bool _disposed = false;
  StreamSubscription<SupabaseStreamEvent>? _watchSubscription;

  /// The Supabase client every query runs against.
  SupabaseClient get client => _service.client;

  /// The service behind [client], for subclasses that need the raw accessor.
  @protected
  SupabaseService get service => _service;

  /// Current lifecycle of the controller.
  ControllerStatus get status => _status;

  /// True while a query started by [runAction] or [runQuery] is running.
  bool get isLoading => _status == ControllerStatus.loading;

  /// True when the last operation failed; read [error] for the reason.
  bool get hasError => _status == ControllerStatus.error;

  /// Human readable reason for the last failure, if any.
  String? get error => _error;

  /// True while a realtime subscription opened by [watchTable] is active.
  bool get isWatching => _watchSubscription != null;

  /// Runs a write that has no useful return value.
  ///
  /// Sets [status] to [ControllerStatus.loading], then to
  /// [ControllerStatus.ready] on success or [ControllerStatus.error] with
  /// [error] filled in on failure. The failure is never thrown: callers read
  /// [status] and [error] instead.
  @protected
  Future<void> runAction(Future<void> Function() operation) async {
    _begin();
    try {
      await operation();
      _status = ControllerStatus.ready;
    } on Object catch (error) {
      _fail(error);
    } finally {
      notifySafely();
    }
  }

  /// Runs a read and returns its result, or `null` when it failed.
  ///
  /// Same status bookkeeping as [runAction]; state fields are left untouched
  /// on failure so a refresh error never wipes data already on screen.
  @protected
  Future<T?> runQuery<T>(Future<T> Function() operation) async {
    _begin();
    try {
      final result = await operation();
      _status = ControllerStatus.ready;
      return result;
    } on Object catch (error) {
      _fail(error);
      return null;
    } finally {
      notifySafely();
    }
  }

  /// Subscribes to a realtime table stream, replacing any previous one.
  ///
  /// [onData] receives the full row set emitted by the stream and should
  /// write it into the controller's fields; the base class takes care of
  /// notifying listeners. Realtime failures land in [error] without losing
  /// the rows already received.
  @protected
  void watchTable(
    Stream<SupabaseStreamEvent> stream, {
    required void Function(List<Map<String, dynamic>> rows) onData,
  }) {
    stopWatch();
    _watchSubscription = stream.listen(
      (rows) {
        onData(rows);
        _status = ControllerStatus.ready;
        notifySafely();
      },
      onError: (Object error) {
        _fail(error);
        notifySafely();
      },
    );
  }

  /// Cancels the realtime subscription opened by [watchTable], if any.
  void stopWatch() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  /// Clears [error] and returns to [ControllerStatus.idle] after a failure.
  void clearError() {
    if (_error == null && _status != ControllerStatus.error) return;
    _error = null;
    if (_status == ControllerStatus.error) _status = ControllerStatus.idle;
    notifySafely();
  }

  /// Announces a change made directly to the controller's fields.
  @protected
  void notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    super.dispose();
  }

  void _begin() {
    _status = ControllerStatus.loading;
    _error = null;
    notifySafely();
  }

  void _fail(Object error) {
    _error = describeError(error);
    _status = ControllerStatus.error;
  }
}

/// Turns a Supabase failure into a message safe to show in the UI.
///
/// Supabase errors extend [SupabaseException] (the postgrest, auth, storage
/// and functions packages all share that hierarchy); anything else falls
/// back to `toString`.
String describeError(Object error) {
  if (error is SupabaseApiException) {
    return '${error.message} (${error.errorCode ?? 'HTTP ${error.statusCode}'})';
  }
  if (error is SupabaseException) {
    final code = error.errorCode;
    return code == null ? error.message : '${error.message} ($code)';
  }
  if (error is RealtimeSubscribeException) {
    return 'Realtime subscription failed: ${error.status.name}';
  }
  return error.toString();
}
