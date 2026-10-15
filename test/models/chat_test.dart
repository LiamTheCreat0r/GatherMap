import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/chat.dart';

void main() {
  group('Chat payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = Chat.insert(circleId: 'circle-1');

      expect(payload, {'circle_id': 'circle-1'});
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('event_id'), isFalse);
      expect(payload.containsKey('friend_id'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = Chat.update(eventId: 'event-1');

      expect(payload, {'event_id': 'event-1'});
      expect(payload.containsKey('circle_id'), isFalse);
      expect(payload.containsKey('friend_id'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final chat = Chat.fromJson({
        'id': 'c-1',
        'circle_id': null,
        'event_id': 'event-1',
        'friend_id': null,
      });

      expect(chat.id, 'c-1');
      expect(chat.circleId, isNull);
      expect(chat.eventId, 'event-1');
      expect(chat.friendId, isNull);
      expect(Chat.converter([chat.toJson()]), hasLength(1));
    });
  });
}
