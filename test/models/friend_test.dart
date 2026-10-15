import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/friend.dart';

void main() {
  group('Friend payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = Friend.insert(
        userId1: 'user-1',
        userId2: 'user-2',
      );

      expect(payload, {
        'user_id_1': 'user-1',
        'user_id_2': 'user-2',
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('friends_since'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = Friend.update(userId1: 'user-3');

      expect(payload, {'user_id_1': 'user-3'});
      expect(payload.containsKey('user_id_2'), isFalse);
      expect(payload.containsKey('friends_since'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final friend = Friend.fromJson({
        'id': 'f-1',
        'friends_since': '2026-10-17T16:30:00+00:00',
        'user_id_1': 'user-1',
        'user_id_2': 'user-2',
      });

      expect(friend.id, 'f-1');
      expect(friend.friendsSince, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(friend.userId1, 'user-1');
      expect(friend.userId2, 'user-2');
      expect(Friend.converter([friend.toJson()]), hasLength(1));
    });
  });
}
