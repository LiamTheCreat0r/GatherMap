import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../../core/state/base_controller.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';
import '../domain/event_schedule.dart' as schedule;

/// Presentation state for the events feature.
///
/// Owns the loaded list of [Event]s plus the detail row in [selected], and can
/// follow the table over realtime with [watch]. All I/O goes through the
/// injected [EventRepository], so this class never imports Supabase and tests
/// can drive it with a hand-written fake.
class EventController extends BaseController {
  EventController(this._repository);

  final EventRepository _repository;

  List<Event> _events = const [];
  Event? _selected;

  /// Events currently held by the controller, in no guaranteed order —
  /// sort them through [upcomingAndPast] or your own comparator.
  List<Event> get events => List.unmodifiable(_events);

  /// The event loaded last by [fetchById], [create] or [update].
  Event? get selected => _selected;

  /// Loads every event the current RLS policies allow the client to see.
  Future<void> fetch() => runAction(() async {
    _events = await _repository.fetch();
  });

  /// Loads events scheduled at or after now, soonest first.
  Future<void> fetchUpcoming() => runAction(() async {
    _events = await _repository.fetch(scope: EventScope.upcoming);
  });

  /// Loads events already in the past, most recent first.
  Future<void> fetchPast() => runAction(() async {
    _events = await _repository.fetch(scope: EventScope.past);
  });

  /// Loads one event into [selected] and returns it, or `null` when the id
  /// matches no row.
  Future<Event?> fetchById(String id) => runQuery<Event?>(() async {
    _selected = await _repository.fetchById(id);
    return _selected;
  });

  /// Inserts a new event, prepends it to [events] and returns it.
  Future<Event?> create({
    required String ownerId,
    required DateTime scheduledAt,
    required String location,
    required String name,
    required String emojiIcon,
    String? color,
    required bool isPublic,
    double? latitude,
    double? longitude,
  }) => runQuery<Event?>(() async {
    final created = await _repository.create(
      NewEvent(
        ownerId: ownerId,
        scheduledAt: scheduledAt,
        location: location,
        name: name,
        emojiIcon: emojiIcon,
        color: color,
        isPublic: isPublic,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    _events = [created, ..._events];
    _selected = created;
    return created;
  });

  /// Patches the event with [id]; omitted fields keep their stored value.
  ///
  /// Returns the updated row, or `null` when the id matches no row or the
  /// request failed.
  Future<Event?> update(
    String id, {
    DateTime? scheduledAt,
    String? location,
    String? name,
    String? emojiIcon,
    String? color,
    bool? isPublic,
  }) => runQuery<Event?>(() async {
    final updated = await _repository.update(
      id,
      EventPatch(
        scheduledAt: scheduledAt,
        location: location,
        name: name,
        emojiIcon: emojiIcon,
        color: color,
        isPublic: isPublic,
      ),
    );
    if (updated == null) return null;
    _events = [for (final event in _events) event.id == id ? updated : event];
    if (_selected?.id == id) _selected = updated;
    return updated;
  });

  /// Deletes the event with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await _repository.delete(id);
    _events = _events.where((event) => event.id != id).toList();
    if (_selected?.id == id) _selected = null;
  });

  /// Follows the whole `event` table over realtime, newest first.
  void watch() {
    watchTable(
      _repository.watch(),
      onData: (rows) => _events = rows,
    );
  }

  /// Splits [events] into upcoming and past — the two sections of the Events
  /// tab. Delegates to the pure [schedule.splitUpcoming].
  static ({List<Event> upcoming, List<Event> past}) splitUpcoming(
    List<Event> events, {
    DateTime? now,
  }) => schedule.splitUpcoming(events, now: now);

  /// [splitUpcoming] applied to the loaded [events].
  ({List<Event> upcoming, List<Event> past}) upcomingAndPast({DateTime? now}) =>
      schedule.splitUpcoming(_events, now: now);

  /// Replaces the loaded list without a query.
  ///
  /// Lets a test drive [upcomingAndPast] without a repository; production code
  /// fills the list through [fetch], [fetchUpcoming], [fetchPast], [create],
  /// [update] or [watch].
  @visibleForTesting
  set events(List<Event> value) {
    _events = value;
    notifySafely();
  }
}
