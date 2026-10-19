import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/profile.dart';

void main() {
  group('Profile payload builders', () {
    test('update renders the columns the table expects', () {
      final birthdate = DateTime(1995, 4, 12);

      final payload = Profile.update(
        username: 'camille_d',
        name: 'Camille',
        surname: 'Durand',
        birthdate: birthdate,
        city: 'Toulouse',
        privateAccount: true,
        onboardingCompleted: true,
      );

      expect(payload, {
        'username': 'camille_d',
        'name': 'Camille',
        'surname': 'Durand',
        'birthdate': birthdate.toIso8601String(),
        'city': 'Toulouse',
        'private_account': true,
        'onboarding_completed': true,
      });

      // Omitted fields keep their stored value rather than being nulled.
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('profile_picture'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('update never carries a credential column', () {
      final payload = Profile.update(username: 'camille_d');

      expect(payload.keys, isNot(contains('hash_password')));
      expect(payload.keys, isNot(contains('email')));
    });

    test('insert keeps the id so a missing trigger row can be created', () {
      final payload = Profile.insert(
        id: 'p-1',
        username: 'camille_d',
        onboardingCompleted: true,
      );

      expect(payload['id'], 'p-1');
      expect(payload['username'], 'camille_d');
      expect(payload['onboarding_completed'], true);
    });

    test('fromJson reads a complete row', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'username': 'camille_d',
        'name': 'Camille',
        'surname': 'Durand',
        'birthdate': '1995-04-12',
        'city': 'Toulouse',
        'profile_picture': 'avatars/p-1.png',
        'private_account': true,
        'onboarding_completed': true,
        'created_at': '2026-10-19T09:00:00.000Z',
      });

      expect(profile.id, 'p-1');
      expect(profile.username, 'camille_d');
      expect(profile.birthdate, DateTime(1995, 4, 12));
      expect(profile.city, 'Toulouse');
      expect(profile.profilePicture, 'avatars/p-1.png');
      expect(profile.privateAccount, isTrue);
      expect(profile.onboardingCompleted, isTrue);
      expect(profile.createdAt, isNotNull);
    });

    test('fromJson tolerates the row the sign-up trigger creates', () {
      // Only id and the names are known at that point, and the username and
      // birth date are null until onboarding writes them.
      final profile = Profile.fromJson({
        'id': 'p-2',
        'name': 'Alex',
        'surname': '',
      });

      expect(profile.id, 'p-2');
      expect(profile.username, isNull);
      expect(profile.name, 'Alex');
      expect(profile.birthdate, isNull);
      expect(profile.city, isNull);
      expect(profile.privateAccount, isFalse);
      expect(profile.onboardingCompleted, isFalse);
      expect(profile.createdAt, isNull);
    });
  });
}
