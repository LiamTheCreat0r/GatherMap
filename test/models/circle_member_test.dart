import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/circle_member.dart';

void main() {
  group('CircleMember payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = CircleMember.insert(
        userId: 'user-1',
        circleId: 'circle-1',
        userNickname: 'alice',
      );

      expect(payload, {
        'user_id': 'user-1',
        'circle_id': 'circle-1',
        'user_nickname': 'alice',
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = CircleMember.update(userNickname: null);

      // user_nickname is explicitly provided as null and gets omitted by the
      // generator, just like any other untouched nullable field.
      expect(payload, {});
      expect(payload.containsKey('user_id'), isFalse);
      expect(payload.containsKey('circle_id'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final member = CircleMember.fromJson({
        'id': 'm-1',
        'user_id': 'user-1',
        'circle_id': 'circle-1',
        'created_at': null,
        'user_nickname': null,
      });

      expect(member.id, 'm-1');
      expect(member.userId, 'user-1');
      expect(member.circleId, 'circle-1');
      expect(member.createdAt, isNull);
      expect(member.userNickname, isNull);
      expect(CircleMember.converter([member.toJson()]), hasLength(1));
    });
  });
}
