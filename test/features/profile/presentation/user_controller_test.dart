import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/profile/presentation/user_controller.dart';
import 'package:gathermap/models/user.dart';

User _user(String id) => User(
      id: id,
      createdAt: null,
      birthdate: DateTime(1990, 1, 1),
      username: id,
      name: 'Name',
      surname: 'Surname',
      city: 'Paris',
      email: '$id@example.com',
      hashPassword: 'hash',
      profilePicture: null,
      privateAccount: false,
    );

void main() {
  group('UserController state', () {
    test('setCurrent stores the profile and notifies', () {
      final controller = UserController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.current, isNull);
      final user = _user('u-1');
      controller.setCurrent(user);
      expect(controller.current, user);
      expect(notifications, 1);

      controller.setCurrent(null);
      expect(controller.current, isNull);
      expect(notifications, 2);
    });
  });
}
