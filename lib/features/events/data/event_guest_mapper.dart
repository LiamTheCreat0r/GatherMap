import '../../../../models/event_invitation.dart' as invitation;
import '../../../../models/profile.dart' as row;
import '../domain/event_guest.dart';

/// Joins `event_invitation` rows with `profiles` rows into the domain guest
/// book.
///
/// The single bridge between `lib/models/` and the event detail sheet for
/// people data, so a schema regen only ripples through this class.
class EventGuestMapper {
  const EventGuestMapper();

  /// Domain person from a generated `Profile` row, or `null` when the row is
  /// missing.
  EventPerson? toPerson(row.Profile? source) {
    if (source == null) return null;

    final username = source.username?.trim() ?? '';
    final fullName = '${source.name} ${source.surname}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? username : 'Invité');

    return EventPerson(
      id: source.id ?? '',
      displayName: displayName,
      username: username,
      profilePicture: source.profilePicture,
    );
  }

  /// Combines [invitations] with [profiles] into a [EventGuestBook].
  ///
  /// A missing profile still produces a guest row with a generic label, so an
  /// invitation hidden by RLS does not silently disappear from the count.
  EventGuestBook toBook({
    required List<invitation.EventInvitation> invitations,
    required List<row.Profile> profiles,
    required String ownerId,
  }) {
    final profilesById = <String, row.Profile>{
      for (final profile in profiles)
        if (profile.id != null && profile.id!.isNotEmpty) profile.id!: profile,
    };

    EventPerson personFor(String userId) {
      final mapped = toPerson(profilesById[userId]);
      if (mapped != null) return mapped;
      return EventPerson(id: userId, displayName: 'Invité');
    }

    return EventGuestBook(
      organizer: toPerson(profilesById[ownerId]),
      guests: [
        for (final entry in invitations)
          EventGuest(person: personFor(entry.userId), accepted: entry.accepted),
      ],
    );
  }
}
