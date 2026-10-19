import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/state/base_controller.dart';

/// Minimal controller that exposes the two protected runners so their status
/// bookkeeping can be asserted without a database.
class _FakeController extends BaseController {
  int calls = 0;

  Future<void> actionSucceeds() =>
      runAction(() async => Future<void>.delayed(Duration.zero));

  Future<void> actionFails(Object error) => runAction(() async => throw error);

  Future<int?> querySucceeds(int value) => runQuery<int?>(() async => value);

  Future<int?> queryFails(Object error) =>
      runQuery<int?>(() async => throw error);
}

void main() {
  group('BaseController.runAction / runQuery', () {
    late _FakeController controller;
    late int notifications;

    setUp(() {
      controller = _FakeController();
      notifications = 0;
      controller.addListener(() => notifications++);
    });

    test('starts idle with no error', () {
      expect(controller.status, ControllerStatus.idle);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.error, isNull);
      expect(controller.isWatching, isFalse);
    });

    test(
      'a successful action ends ready and notifies loading then ready',
      () async {
        await controller.actionSucceeds();

        expect(controller.status, ControllerStatus.ready);
        expect(controller.error, isNull);
        expect(notifications, 2);
      },
    );

    test('a failing action records the message instead of throwing', () async {
      await expectLater(controller.actionFails(StateError('boom')), completes);

      expect(controller.status, ControllerStatus.error);
      expect(controller.hasError, isTrue);
      expect(controller.error, contains('boom'));
      expect(notifications, 2);
    });

    test('a successful query returns its value and ends ready', () async {
      expect(await controller.querySucceeds(7), 7);
      expect(controller.status, ControllerStatus.ready);
      expect(controller.error, isNull);
    });

    test('a failing query returns null and keeps the error', () async {
      expect(await controller.queryFails(StateError('nope')), isNull);
      expect(controller.status, ControllerStatus.error);
      expect(controller.error, contains('nope'));
    });

    test('clearError goes back to idle', () async {
      await controller.actionFails(StateError('boom'));
      controller.clearError();

      expect(controller.status, ControllerStatus.idle);
      expect(controller.error, isNull);
    });

    test('clearError is a no-op when there is nothing to clear', () {
      controller.clearError();
      expect(notifications, 0);
    });

    test('an operation finishing after dispose does not notify', () async {
      final pending = controller.actionSucceeds();
      controller.dispose();

      await expectLater(pending, completes);
      expect(notifications, 1); // only the loading notification
    });
  });
}
