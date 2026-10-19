import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/event.dart';
import '../models/supadart_header.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `event` table.
///
/// Owns the loaded list of [Event] rows plus the detail row in [selected],
/// and can follow the table over realtime with [watch].
class EventController extends BaseController {
  EventController({super.service});

  List<Event> _events = const [];
  Event? _selected;

  /// Events currently held by the controller, in no guaranteed order —
  /// sort them through [upcomingAndPast] or your own comparator.
  List<Event> get events => List.unmodifiable(_events);

  /// The event loaded last by [fetchById], [create] or [update].
  Event? get selected => _selected;

  /// Loads every event the current RLS policies allow the client to see.
  Future<void> fetch() => runAction(() async {
    final rows = await client.event.select().order(
      Event.c_scheduledAt,
      ascending: false,
    );
    _events = Event.converter(rows);
  });

  /// Loads events scheduled at or after now, soonest first.
  Future<void> fetchUpcoming() => runAction(() async {
    final rows = await client.event
        .select()
        .gte(Event.c_scheduledAt, DateTime.now().toUtc().toIso8601String())
        .order(Event.c_scheduledAt);
    _events = Event.converter(rows);
  });

  /// Loads events already in the past, most recent first.
  Future<void> fetchPast() => runAction(() async {
    final rows = await client.event
        .select()
        .lt(Event.c_scheduledAt, DateTime.now().toUtc().toIso8601String())
        .order(Event.c_scheduledAt, ascending: false);
    _events = Event.converter(rows);
  });

  /// Loads one event into [selected] and returns it, or `null` when the id
  /// matches no row.
  Future<Event?> fetchById(String id) => runQuery<Event?>(() async {
    final rows = await client.event.select().eq(Event.c_id, id).limit(1);
    _selected = rows.isEmpty ? null : Event.converterSingle(rows.first);
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
    final rows = await client.event
        .insert(
          Event.insert(
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
        )
        .select();
    if (rows.isEmpty) return null;
    final created = Event.converterSingle(rows.first);
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
    final rows = await client.event
        .update(
          Event.update(
            scheduledAt: scheduledAt,
            location: location,
            name: name,
            emojiIcon: emojiIcon,
            color: color,
            isPublic: isPublic,
          ),
        )
        .eq(Event.c_id, id)
        .select();
    if (rows.isEmpty) return null;
    final updated = Event.converterSingle(rows.first);
    _events = [for (final event in _events) event.id == id ? updated : event];
    if (_selected?.id == id) _selected = updated;
    return updated;
  });

  /// Deletes the event with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.event.delete().eq(Event.c_id, id);
    _events = _events.where((event) => event.id != id).toList();
    if (_selected?.id == id) _selected = null;
  });

  /// Follows the whole `event` table over realtime, newest first.
  void watch() {
    watchTable(
      client.event
          .stream(primaryKey: [Event.c_id])
          .order(Event.c_scheduledAt, ascending: false),
      onData: (rows) => _events = Event.converter(rows),
    );
  }

  /// Splits [events] into events after [now] (ascending) and events at or
  /// before [now] (most recent first) — the two sections of the Events tab.
  ///
  /// Static and clock-injected so it can be unit-tested without a database.
  static ({List<Event> upcoming, List<Event> past}) splitUpcoming(
    List<Event> events, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final upcoming =
        events.where((event) => event.scheduledAt.isAfter(reference)).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past =
        events.where((event) => !event.scheduledAt.isAfter(reference)).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return (upcoming: upcoming, past: past);
  }

  /// [splitUpcoming] applied to the loaded [events].
  ({List<Event> upcoming, List<Event> past}) upcomingAndPast({DateTime? now}) =>
      splitUpcoming(_events, now: now);

  /// Replaces the loaded list without a query.
  ///
  /// Lets a test drive [upcomingAndPast] without a database; production code
  /// fills the list through [fetch], [fetchUpcoming], [fetchPast], [create],
  /// [update] or [watch].
  @visibleForTesting
  set events(List<Event> value) {
    _events = value;
    notifySafely();
  }
}
