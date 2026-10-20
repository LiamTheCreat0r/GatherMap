import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/profile/presentation/profile_controller.dart';
import 'package:gathermap/models/profile.dart';

Profile _profile(String id, {bool onboardingCompleted = true}) => Profile(
  id: id,
  username: id,
  name: 'Camille',
  surname: 'Durand',
  birthdate: DateTime(1995, 4, 12),
  city: 'Toulouse',
  profilePicture: null,
  privateAccount: false,
  onboardingCompleted: onboardingCompleted,
  createdAt: null,
);

void main() {
  group('ProfileController state', () {
    test('starts signed out, with nothing loaded', () {
      final controller = ProfileController();
      addTearDown(controller.dispose);

      expect(controller.current, isNull);
      expect(controller.hasProfile, isFalse);
      expect(controller.isLoaded, isFalse);
      expect(controller.isOnboardingComplete, isFalse);
      expect(controller.sessionUserId, isNull);
    });

    test('setCurrent stores the profile and notifies', () {
      final controller = ProfileController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      final profile = _profile('u-1');
      controller.setCurrent(profile);
      expect(controller.current, profile);
      expect(controller.hasProfile, isTrue);
      expect(controller.isLoaded, isTrue);
      expect(notifications, 1);

      controller.setCurrent(null);
      expect(controller.current, isNull);
      expect(notifications, 2);
    });

    test('isOnboardingComplete follows the profile flag', () {
      final controller = ProfileController();
      addTearDown(controller.dispose);

      controller.setCurrent(_profile('u-1', onboardingCompleted: false));
      expect(controller.isOnboardingComplete, isFalse);

      controller.setCurrent(_profile('u-1'));
      expect(controller.isOnboardingComplete, isTrue);
    });

    test('syncSession ignores a session that has not changed', () {
      final controller = ProfileController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      // The app starts signed out, so the first report is a no-op.
      controller.syncSession(null);
      expect(notifications, 0);
      expect(controller.isLoaded, isFalse);
    });

    test('syncSession clears the cached profile when the user signs out', () async {
      final controller = ProfileController();
      addTearDown(controller.dispose);

      // Signing in queues a load. Supabase is not initialized in a unit test,
      // so that load fails — which is the point: the controller reports it and
      // never throws. setCurrent stands in for the row it would have fetched.
      controller.syncSession('u-1');
      await Future<void>.delayed(Duration.zero);
      controller.setCurrent(_profile('u-1'));
      expect(controller.hasProfile, isTrue);

      controller.syncSession(null);
      await Future<void>.delayed(Duration.zero);

      expect(controller.sessionUserId, isNull);
      expect(controller.current, isNull);
      expect(controller.profiles, isEmpty);
      expect(controller.isLoaded, isTrue);
      // The failure from the previous session must not outlive it.
      expect(controller.hasError, isFalse);
    });
  });
}
