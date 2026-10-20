/// A person attached to an event — a guest or the organiser.
///
/// Kept independent of the generated `user` row so the presentation layer only
/// ever sees the handful of fields the event screen actually renders.
class EventPerson {
  const EventPerson({
    required this.id,
    required this.displayName,
    this.username = '',
    this.profilePicture,
  });

  /// The `user.id` this person comes from.
  final String id;

  /// Full name when known, otherwise the username, otherwise a generic label.
  final String displayName;

  /// The profile's unique handle, without the leading `@`.
  final String username;

  /// Optional profile picture URL.
  final String? profilePicture;
}

/// One invitation row joined with its person.
class EventGuest {
  const EventGuest({required this.person, required this.accepted});

  final EventPerson person;

  /// `true` = attending, `false` = declined, `null` = no answer yet.
  final bool? accepted;
}

/// The guests and organiser of one event, as the detail sheet needs them.
class EventGuestBook {
  const EventGuestBook({this.organizer, this.guests = const []});

  /// The event owner, when their profile is visible to the caller.
  final EventPerson? organizer;

  /// Every invitation row with a person attached, in query order.
  final List<EventGuest> guests;
}
