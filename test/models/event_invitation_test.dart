import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/models/event_invitation.dart';

void main() {
  group('EventInvitation payload builders', () {
    test('insert renders the columns the table expects', () {
      final payload = EventInvitation.insert(
        userId: 'user-1',
        eventId: 'event-1',
      );

      expect(payload, {
        'user_id': 'user-1',
        'event_id': 'event-1',
      });
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('accepted'), isFalse);
    });

    test('update omits untouched fields but keeps explicit false', () {
      final payload = EventInvitation.update(accepted: false);

      expect(payload, {'accepted': false});
      expect(payload.containsKey('user_id'), isFalse);
      expect(payload.containsKey('event_id'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('fromJson survives the shapes PostgREST returns', () {
      final invitation = EventInvitation.fromJson({
        'id': 'i-1',
        'created_at': '2026-10-17T16:30:00+00:00',
        'accepted': null,
        'user_id': 'user-1',
        'event_id': 'event-1',
      });

      expect(invitation.id, 'i-1');
      expect(invitation.createdAt, DateTime.parse('2026-10-17T16:30:00+00:00'));
      expect(invitation.accepted, isNull);
      expect(invitation.userId, 'user-1');
      expect(invitation.eventId, 'event-1');
      expect(EventInvitation.converter([invitation.toJson()]), hasLength(1));
    });
  });
}
