import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/circle.dart';

void main() {
  group('Circle payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = Circle.insert(ownerId: 'owner-1');

      expect(payload, {'owner_id': 'owner-1'});
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = Circle.update(ownerId: 'owner-2');

      expect(payload, {'owner_id': 'owner-2'});
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final circle = Circle.fromJson({
        'id': 'circle-1',
        'created_at': '2026-10-17T16:30:00+00:00',
        'owner_id': 'owner-1',
      });

      expect(circle.id, 'circle-1');
      expect(circle.createdAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(circle.ownerId, 'owner-1');
      expect(Circle.converter([circle.toJson()]), hasLength(1));
    });
  });
}
