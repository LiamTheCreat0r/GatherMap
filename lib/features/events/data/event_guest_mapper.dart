import '../../../../models/event_invitation.dart' as invitation;
import '../../../../models/user.dart' as row;
import '../domain/event_guest.dart';

/// Joins `event_invitation` rows with `user` rows into the domain guest book.
///
/// The single bridge between `lib/models/` and the event detail sheet for
/// people data, so a schema regen only ripples through this class.
class EventGuestMapper {
  const EventGuestMapper();

  /// Domain person from a generated `user` row, or `null` when the row is
  /// missing.
  EventPerson? toPerson(row.User? source) {
    if (source == null) return null;

    final fullName = '${source.name} ${source.surname}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : (source.username.isNotEmpty ? source.username : 'Invité');

    return EventPerson(
      id: source.id ?? '',
      displayName: displayName,
      username: source.username,
      profilePicture: source.profilePicture,
    );
  }

  /// Combines [invitations] with [users] into a [EventGuestBook].
  ///
  /// A missing profile still produces a guest row with a generic label, so an
  /// invitation hidden by RLS does not silently disappear from the count.
  EventGuestBook toBook({
    required List<invitation.EventInvitation> invitations,
    required List<row.User> users,
    required String ownerId,
  }) {
    final usersById = <String, row.User>{
      for (final user in users)
        if (user.id != null && user.id!.isNotEmpty) user.id!: user,
    };

    EventPerson personFor(String userId) {
      final mapped = toPerson(usersById[userId]);
      if (mapped != null) return mapped;
      return EventPerson(id: userId, displayName: 'Invité');
    }

    return EventGuestBook(
      organizer: toPerson(usersById[ownerId]),
      guests: [
        for (final entry in invitations)
          EventGuest(person: personFor(entry.userId), accepted: entry.accepted),
      ],
    );
  }
}
