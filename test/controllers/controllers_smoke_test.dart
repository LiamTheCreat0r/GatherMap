import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/controllers/controllers.dart';

/// Constructing a controller must not touch `Supabase.instance`: the service
/// resolves its client lazily, so the whole layer can be built before
/// `Supabase.initialize` runs (and in tests, where it never runs).
void main() {
  test('every controller can be built without a Supabase client', () {
    final controllers = <BaseController>[
      UserController(),
      EventController(),
      EventInvitationController(),
      CircleController(),
      CircleMemberController(),
      ChatController(),
      MessageController(),
      FriendController(),
      BlockedUserController(),
    ];

    for (final controller in controllers) {
      expect(controller.status, ControllerStatus.idle);
      expect(controller.error, isNull);
      controller.dispose();
    }
  });
}
