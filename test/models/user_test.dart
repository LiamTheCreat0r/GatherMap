import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/user.dart';

void main() {
  group('User payload builders', () {
    test('insert renders the columns the table expects', () {
      final birthdate = DateTime(1990, 1, 1);

      final payload = User.insert(
        birthdate: birthdate,
        username: 'alice',
        name: 'Alice',
        surname: 'Doe',
        city: 'Paris',
        email: 'alice@example.com',
        hashPassword: 'hash',
        privateAccount: false,
      );

      expect(payload, {
        'birthdate': birthdate.toIso8601String(),
        'username': 'alice',
        'name': 'Alice',
        'surname': 'Doe',
        'city': 'Paris',
        'email': 'alice@example.com',
        'hash_password': 'hash',
        'private_account': false,
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('profile_picture'), isFalse);
    });

    test('update omits untouched fields but keeps explicit false', () {
      final payload = User.update(name: 'Renamed', privateAccount: false);

      expect(payload, {'name': 'Renamed', 'private_account': false});
      expect(payload.containsKey('username'), isFalse);
      expect(payload.containsKey('birthdate'), isFalse);
      expect(payload.containsKey('hash_password'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final user = User.fromJson({
        'id': 'u-1',
        'created_at': '2026-10-17T16:30:00+00:00',
        'birthdate': '1990-01-01T00:00:00.000',
        'username': 'alice',
        'name': 'Alice',
        'surname': 'Doe',
        'city': 'Paris',
        'email': 'alice@example.com',
        'hash_password': 'hash',
        'profile_picture': null,
        'private_account': false,
      });

      expect(user.id, 'u-1');
      expect(user.createdAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(user.birthdate, DateTime.parse('1990-01-01T00:00:00.000'));
      expect(user.profilePicture, isNull);
      expect(user.privateAccount, isFalse);
      expect(User.converter([user.toJson()]), hasLength(1));
    });
  });
}
