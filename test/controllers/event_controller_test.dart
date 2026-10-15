import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/controllers/event_controller.dart';
import 'package:gathermap/models/event.dart';

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
);

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
      final controller = EventController();
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

  group('Event payload builders', () {
    test('insert renders the columns the table expects', () {
      final scheduledAt = DateTime(2026, 10, 17, 18, 30);

      final payload = Event.insert(
        ownerId: 'owner-1',
        scheduledAt: scheduledAt,
        location: 'Café de la Gare',
        name: 'Apéro des voisins',
        emojiIcon: '🥂',
        isPublic: true,
      );

      expect(payload, {
        'owner_id': 'owner-1',
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'location': 'Café de la Gare',
        'name': 'Apéro des voisins',
        'emoji_icon': '🥂',
        'is_public': true,
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('color'), isFalse);
    });

    test('update omits untouched fields but keeps explicit false', () {
      final payload = Event.update(name: 'Renamed', isPublic: false);

      expect(payload, {'name': 'Renamed', 'is_public': false});
      expect(payload.containsKey('location'), isFalse);
      expect(payload.containsKey('scheduled_at'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final event = Event.fromJson({
        'id': 'e-1',
        'owner_id': 'owner-1',
        'scheduled_at': '2026-10-17T16:30:00+00:00',
        'location': 'Parc de Sceaux',
        'created_at': null,
        'name': 'Randonnée',
        'emoji_icon': '🌄',
        'color': '#0A84FF',
        'is_public': false,
      });

      expect(event.id, 'e-1');
      expect(event.scheduledAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(event.isPublic, isFalse);
      expect(Event.converter([event.toJson()]), hasLength(1));
    });
  });
}
