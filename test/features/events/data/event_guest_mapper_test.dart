import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/events/data/event_guest_mapper.dart';
import 'package:gathermap/models/event_invitation.dart' as invitation;
import 'package:gathermap/models/user.dart' as row;

row.User _user({
  required String id,
  required String name,
  required String surname,
  String username = 'handle',
}) => row.User(
  id: id,
  createdAt: DateTime.utc(2026),
  birthdate: DateTime.utc(2000),
  username: username,
  name: name,
  surname: surname,
  city: 'Toulouse',
  email: '$username@example.com',
  hashPassword: 'hash',
  profilePicture: null,
  privateAccount: false,
);

invitation.EventInvitation _invitation(String userId, bool? accepted) =>
    invitation.EventInvitation(
      id: 'inv-$userId',
      createdAt: DateTime.utc(2026, 10, 1),
      accepted: accepted,
      userId: userId,
      eventId: 'evt-1',
    );

void main() {
  const mapper = EventGuestMapper();

  test('joins invitations with profiles and keeps their answer', () {
    final book = mapper.toBook(
      invitations: [
        _invitation('u1', true),
        _invitation('u2', null),
        _invitation('u3', false),
      ],
      users: [
        _user(id: 'u1', name: 'Léa', surname: 'Martin', username: 'lea'),
        _user(id: 'u2', name: 'Tom', surname: 'Bernard', username: 'tom'),
        _user(id: 'u3', name: 'Inès', surname: 'Petit', username: 'ines'),
      ],
      ownerId: 'u1',
    );

    expect(book.organizer?.displayName, 'Léa Martin');
    expect(book.guests.map((guest) => guest.person.displayName), [
      'Léa Martin',
      'Tom Bernard',
      'Inès Petit',
    ]);
    expect(book.guests.map((guest) => guest.accepted), [true, null, false]);
  });

  test('a profile hidden by RLS still counts as a guest', () {
    final book = mapper.toBook(
      invitations: [_invitation('missing', true)],
      users: const [],
      ownerId: 'owner',
    );

    expect(book.guests.single.person.id, 'missing');
    expect(book.guests.single.person.displayName, 'Invité');
    expect(book.organizer, isNull);
  });

  test('falls back to the username when the full name is empty', () {
    final person = mapper.toPerson(
      _user(id: 'u1', name: '', surname: '', username: 'lea'),
    );

    expect(person?.displayName, 'lea');
  });
}
