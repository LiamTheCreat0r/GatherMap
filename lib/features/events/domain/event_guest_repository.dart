import 'event_guest.dart';

/// How the event detail sheet reads guests and the organiser.
///
/// Declared in `domain/` so the presentation layer depends on this contract
/// rather than on the `event_invitation`, `user` or Supabase types.
abstract interface class EventGuestRepository {
  /// Loads the invitation rows for [eventId] and the profiles they reference.
  ///
  /// [ownerId] is looked up in the same pass so the sheet can show the
  /// organiser without a second round trip.
  Future<EventGuestBook> fetchForEvent(
    String eventId, {
    required String ownerId,
  });
}
