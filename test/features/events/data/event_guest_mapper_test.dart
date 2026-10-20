import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/events/data/event_guest_mapper.dart';
import 'package:gathermap/models/event_invitation.dart' as invitation;
import 'package:gathermap/models/profile.dart' as row;

row.Profile _profile({
  required String id,
  required String name,
  required String surname,
  String? username = 'handle',
}) => row.Profile(
  id: id,
  username: username,
  name: name,
  surname: surname,
  birthdate: DateTime.utc(2000),
  city: 'Toulouse',
  profilePicture: null,
  privateAccount: false,
  onboardingCompleted: true,
  createdAt: DateTime.utc(2026),
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
      profiles: [
        _profile(id: 'u1', name: 'Léa', surname: 'Martin', username: 'lea'),
        _profile(id: 'u2', name: 'Tom', surname: 'Bernard', username: 'tom'),
        _profile(id: 'u3', name: 'Inès', surname: 'Petit', username: 'ines'),
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
      profiles: const [],
      ownerId: 'owner',
    );

    expect(book.guests.single.person.id, 'missing');
    expect(book.guests.single.person.displayName, 'Invité');
    expect(book.organizer, isNull);
  });

  test('falls back to the username when the full name is empty', () {
    final person = mapper.toPerson(
      _profile(id: 'u1', name: '', surname: '', username: 'lea'),
    );

    expect(person?.displayName, 'lea');
  });
}
