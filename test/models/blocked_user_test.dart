import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/blocked_user.dart';

void main() {
  group('BlockedUser payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = BlockedUser.insert(
        blockerId: 'blocker-1',
        blockedId: 'blocked-1',
      );

      expect(payload, {
        'blocker_id': 'blocker-1',
        'blocked_id': 'blocked-1',
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('blocked_at'), isFalse);
    });

    test('update omits untouched fields', () {
      final payload = BlockedUser.update(blockedId: 'blocked-2');

      expect(payload, {'blocked_id': 'blocked-2'});
      expect(payload.containsKey('blocker_id'), isFalse);
      expect(payload.containsKey('blocked_at'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final blocked = BlockedUser.fromJson({
        'id': 'b-1',
        'blocked_at': '2026-10-17T16:30:00+00:00',
        'blocker_id': 'blocker-1',
        'blocked_id': 'blocked-1',
      });

      expect(blocked.id, 'b-1');
      expect(blocked.blockedAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(blocked.blockerId, 'blocker-1');
      expect(blocked.blockedId, 'blocked-1');
      expect(BlockedUser.converter([blocked.toJson()]), hasLength(1));
    });
  });
}
