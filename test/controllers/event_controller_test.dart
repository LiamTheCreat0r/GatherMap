import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/controllers/event_controller.dart';
import 'package:gathermap/models/event.dart';

Event _event(
  String id,
  DateTime scheduledAt, {
  double? latitude,
  double? longitude,
}) => Event(
  id: id,
  ownerId: 'owner-1',
  scheduledAt: scheduledAt,
  location: 'Somewhere',
  createdAt: null,
  name: id,
  emojiIcon: '🎉',
  color: '#FF5A1F',
  isPublic: true,
  latitude: latitude,
  longitude: longitude,
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
}
