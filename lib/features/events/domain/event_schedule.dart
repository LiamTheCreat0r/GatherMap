import 'event.dart';

/// Splits [events] into events after [now] (ascending) and events at or before
/// [now] (most recent first) — the two sections of the Events tab.
///
/// Free of any I/O and clock-injected, so it can be unit-tested without a
/// database. The Events tab renders the result directly; the controller
/// exposes it through its own `upcomingAndPast` accessor.
({List<Event> upcoming, List<Event> past}) splitUpcoming(
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
