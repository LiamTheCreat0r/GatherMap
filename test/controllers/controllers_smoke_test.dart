import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/controllers/controllers.dart';

/// Constructing a controller must not touch `Supabase.instance`: the service
/// resolves its client lazily, so the whole layer can be built before
/// `Supabase.initialize` runs (and in tests, where it never runs).
///
/// `AuthController` is the one that matters most here — it holds a session, and
/// reading it at construction time would reach into Supabase before the widget
/// tree exists. `AuthGate` is what calls `initialize()`.
void main() {
  test('every controller can be built without a Supabase client', () {
    final controllers = <BaseController>[
      AuthController(),
      ProfileController(),
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
