import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/state/base_controller.dart';
import 'package:gathermap/features/events/domain/event.dart';
import 'package:gathermap/features/events/domain/event_repository.dart';
import 'package:gathermap/features/events/presentation/event_controller.dart';

Event _event(String id, DateTime scheduledAt) => Event(
  id: id,
  ownerId: 'owner-1',
  scheduledAt: scheduledAt,
  location: 'Somewhere',
  createdAt: null,
  name: id,
  emojiIcon: '🎉',
  color: '#FF5A1F',
  isPublic: true,
  latitude: null,
  longitude: null,
);

/// In-memory [EventRepository] so the controller can be driven without
/// Supabase. Only the behaviour each test exercises is implemented; the rest
/// records the call and returns a neutral value.
class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({this.events = const [], this.failure});

  List<Event> events;

  /// When set, every call throws it instead of returning.
  final Object? failure;

  EventScope? lastScope;
  Event? created;
  String? deletedId;

  Future<T> _guard<T>(T Function() body) async {
    if (failure != null) throw failure!;
    return body();
  }

  @override
  Future<List<Event>> fetch({EventScope scope = EventScope.all}) {
    lastScope = scope;
    return _guard(() => events);
  }

  @override
  Future<Event?> fetchById(String id) => _guard(
    () => events.where((event) => event.id == id).firstOrNull,
  );

  @override
  Future<Event> create(NewEvent draft) => _guard(() {
    final event = Event(
      id: 'created-id',
      ownerId: draft.ownerId,
      scheduledAt: draft.scheduledAt,
      location: draft.location,
      createdAt: null,
      name: draft.name,
      emojiIcon: draft.emojiIcon,
      color: draft.color ?? '#FF5A1F',
      isPublic: draft.isPublic,
      latitude: draft.latitude,
      longitude: draft.longitude,
    );
    created = event;
    return event;
  });

  @override
  Future<Event?> update(String id, EventPatch patch) => _guard(() {
    final existing = events.where((event) => event.id == id).firstOrNull;
    if (existing == null) return null;
    return Event(
      id: existing.id,
      ownerId: existing.ownerId,
      scheduledAt: patch.scheduledAt ?? existing.scheduledAt,
      location: patch.location ?? existing.location,
      createdAt: existing.createdAt,
      name: patch.name ?? existing.name,
      emojiIcon: patch.emojiIcon ?? existing.emojiIcon,
      color: patch.color ?? existing.color,
      isPublic: patch.isPublic ?? existing.isPublic,
      latitude: existing.latitude,
      longitude: existing.longitude,
    );
  });

  @override
  Future<void> delete(String id) => _guard(() => deletedId = id);

  @override
  Stream<List<Event>> watch() => Stream.value(events);
}

void main() {
  group('EventController.splitUpcoming', () {
    final now = DateTime(2026, 10, 15, 12);

    test('splits on [now] and sorts upcoming ascending, past descending', () {
      final events = [
        _event('in-two-days', now.add(const Duration(days: 2))),
        _event('three-days-ago', now.subtract(const Duration(days: 3))),
        _event('in-five-days', now.add(const Duration(days: 5))),
        _event('eight-days-ago', now.subtract(const Duration(days: 8))),
      ];

      final result = EventController.splitUpcoming(events, now: now);

      expect(result.upcoming.map((e) => e.id), ['in-two-days', 'in-five-days']);
      expect(result.past.map((e) => e.id), [
        'three-days-ago',
        'eight-days-ago',
      ]);
    });

    test('an event exactly at [now] counts as past', () {
      final result = EventController.splitUpcoming([
        _event('now', now),
      ], now: now);

      expect(result.upcoming, isEmpty);
      expect(result.past, hasLength(1));
    });

    test('upcomingAndPast reads the loaded list', () {
      final controller = EventController(_FakeEventRepository());
      addTearDown(controller.dispose);

      expect(controller.upcomingAndPast(now: now).upcoming, isEmpty);

      controller.events = [
        _event('in-two-days', now.add(const Duration(days: 2))),
      ];

      final result = controller.upcomingAndPast(now: now);
      expect(result.upcoming.map((e) => e.id), ['in-two-days']);
      expect(result.past, isEmpty);
    });
  });

  group('EventController over a repository', () {
    test('fetchUpcoming asks the repository for the upcoming scope', () async {
      final repository = _FakeEventRepository(
        events: [_event('a', DateTime(2026, 10, 20))],
      );
      final controller = EventController(repository);
      addTearDown(controller.dispose);

      await controller.fetchUpcoming();

      expect(repository.lastScope, EventScope.upcoming);
      expect(controller.events.map((e) => e.id), ['a']);
      expect(controller.status, ControllerStatus.ready);
    });

    test('create prepends the new event and selects it', () async {
      final repository = _FakeEventRepository(
        events: [_event('existing', DateTime(2026, 10, 20))],
      );
      final controller = EventController(repository);
      addTearDown(controller.dispose);
      await controller.fetch();

      final created = await controller.create(
        ownerId: 'owner-1',
        scheduledAt: DateTime(2026, 11, 1, 18),
        location: 'Somewhere',
        name: 'New event',
        emojiIcon: '🎉',
        isPublic: true,
      );

      expect(created, isNotNull);
      expect(repository.created?.name, 'New event');
      expect(controller.events.first.id, 'created-id');
      expect(controller.events, hasLength(2));
      expect(controller.selected?.id, 'created-id');
    });

    test('a failing fetch records the error instead of throwing', () async {
      final controller = EventController(
        _FakeEventRepository(failure: StateError('offline')),
      );
      addTearDown(controller.dispose);

      await controller.fetch();

      expect(controller.status, ControllerStatus.error);
      expect(controller.error, contains('offline'));
      expect(controller.events, isEmpty);
    });

    test('remove deletes through the repository and drops the row', () async {
      final repository = _FakeEventRepository(
        events: [_event('gone', DateTime(2026, 10, 20))],
      );
      final controller = EventController(repository);
      addTearDown(controller.dispose);

      await controller.fetch();
      await controller.remove('gone');

      expect(repository.deletedId, 'gone');
      expect(controller.events, isEmpty);
    });

    test('watch feeds the repository stream into the event list', () async {
      final controller = EventController(
        _FakeEventRepository(events: [_event('live', DateTime(2026, 10, 20))]),
      );
      addTearDown(controller.dispose);

      controller.watch();
      await Future<void>.delayed(Duration.zero);

      expect(controller.events.map((e) => e.id), ['live']);
      expect(controller.isWatching, isTrue);
    });
  });
}
