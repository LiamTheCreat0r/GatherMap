import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/event.dart';

void main() {
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
