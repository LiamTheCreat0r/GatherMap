import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/events/data/event_mapper.dart';
import 'package:gathermap/features/events/domain/event_repository.dart';
import 'package:gathermap/models/event.dart' as row;

/// A stored row as the database would hand it back.
row.Event _row({String id = 'evt-1', String color = '#FF5A1F'}) => row.Event(
  id: id,
  ownerId: 'owner-1',
  scheduledAt: DateTime.utc(2026, 10, 15, 18, 30),
  location: 'Café de la Gare',
  createdAt: DateTime.utc(2026, 10, 1, 9),
  name: 'Apéro des voisins',
  emojiIcon: '🎉',
  color: color,
  isPublic: true,
  latitude: 43.6045,
  longitude: 1.4442,
);

void main() {
  const mapper = EventMapper();

  group('EventMapper.toEntity', () {
    test('copies every field across to the domain event', () {
      final entity = mapper.toEntity(_row());

      expect(entity.id, 'evt-1');
      expect(entity.ownerId, 'owner-1');
      expect(entity.scheduledAt, DateTime.utc(2026, 10, 15, 18, 30));
      expect(entity.location, 'Café de la Gare');
      expect(entity.createdAt, DateTime.utc(2026, 10, 1, 9));
      expect(entity.name, 'Apéro des voisins');
      expect(entity.emojiIcon, '🎉');
      expect(entity.color, '#FF5A1F');
      expect(entity.isPublic, isTrue);
      expect(entity.latitude, 43.6045);
      expect(entity.longitude, 1.4442);
    });

    test('falls back to an empty id when the row carries none', () {
      final entity = mapper.toEntity(_row(id: ''));

      expect(entity.id, isEmpty);
      expect(entity.isPinnable, isFalse);
    });
  });

  group('EventMapper.toInsert', () {
    test('uses the snake_case keys the table expects', () {
      final payload = mapper.toInsert(
        NewEvent(
          ownerId: 'owner-1',
          scheduledAt: DateTime.utc(2026, 10, 15, 18, 30),
          location: 'Café de la Gare',
          name: 'Apéro des voisins',
          emojiIcon: '🎉',
          color: '#FF5A1F',
          isPublic: true,
          latitude: 43.6045,
          longitude: 1.4442,
        ),
      );

      expect(payload.keys, containsAll(['owner_id', 'scheduled_at', 'name']));
      expect(payload['owner_id'], 'owner-1');
      expect(payload['is_public'], isTrue);
      // The insert never carries an id: the database assigns it.
      expect(payload.containsKey('id'), isFalse);
    });
  });

  group('EventMapper.toUpdate', () {
    test('omits fields the patch left unset so they survive the write', () {
      final payload = mapper.toUpdate(const EventPatch(name: 'Renamed'));

      expect(payload['name'], 'Renamed');
      expect(payload.containsKey('scheduled_at'), isFalse);
      expect(payload.containsKey('is_public'), isFalse);
    });
  });
}
