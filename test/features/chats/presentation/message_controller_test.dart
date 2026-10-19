import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/chats/presentation/message_controller.dart';

void main() {
  group('MessageController state', () {
    test('clear empties the thread and notifies', () {
      final controller = MessageController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.clear();
      expect(controller.messages, isEmpty);
      expect(controller.chatId, isNull);
      expect(notifications, 1);
    });
  });
}
