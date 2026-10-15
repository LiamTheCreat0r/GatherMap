import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/message.dart';

void main() {
  group('Message payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = Message.insert(
        content: 'Hello',
        senderId: 'sender-1',
        chatId: 'chat-1',
      );

      expect(payload, {
        'content': 'Hello',
        'sender_id': 'sender-1',
        'chat_id': 'chat-1',
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('image'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = Message.update(content: 'Updated');

      expect(payload, {'content': 'Updated'});
      expect(payload.containsKey('image'), isFalse);
      expect(payload.containsKey('sender_id'), isFalse);
      expect(payload.containsKey('chat_id'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final message = Message.fromJson({
        'id': 'm-1',
        'created_at': '2026-10-17T16:30:00+00:00',
        'image': null,
        'content': 'Hello',
        'sender_id': 'sender-1',
        'chat_id': 'chat-1',
      });

      expect(message.id, 'm-1');
      expect(message.createdAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(message.image, isNull);
      expect(message.content, 'Hello');
      expect(message.senderId, 'sender-1');
      expect(message.chatId, 'chat-1');
      expect(Message.converter([message.toJson()]), hasLength(1));
    });
  });
}
