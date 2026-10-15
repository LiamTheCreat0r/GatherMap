import '../models/event_invitation.dart';
import '../models/supadart_header.dart';
import 'base_controller.dart';

/// Controller for the `event_invitation` table.
///
/// An invitation is the row `(user_id, event_id)` plus the [EventInvitation.accepted]
/// answer, so `create` doubles as "invite this person" and
/// [setAccepted] as the RSVP.
class EventInvitationController extends BaseController {
  EventInvitationController({super.service});

  List<EventInvitation> _invitations = const [];

  /// Invitations currently held by the controller.
  List<EventInvitation> get invitations => List.unmodifiable(_invitations);

  /// Loads every invitation sent for [eventId], newest first.
  Future<void> fetchForEvent(String eventId) => runAction(() async {
    final rows = await client.event_invitation
        .select()
        .eq(EventInvitation.c_eventId, eventId)
        .order(EventInvitation.c_createdAt, ascending: false);
    _invitations = EventInvitation.converter(rows);
  });

  /// Loads the invitations addressed to [userId], newest first.
  Future<void> fetchForUser(String userId) => runAction(() async {
    final rows = await client.event_invitation
        .select()
        .eq(EventInvitation.c_userId, userId)
        .order(EventInvitation.c_createdAt, ascending: false);
    _invitations = EventInvitation.converter(rows);
  });

  /// Loads the invitations addressed to [userId] that are still unanswered
  /// (`accepted` is null) or explicitly [accepted].
  Future<void> fetchForUserByAnswer(String userId, {bool? accepted}) =>
      runAction(() async {
        var query = client.event_invitation.select().eq(
          EventInvitation.c_userId,
          userId,
        );
        if (accepted != null) {
          query = query.eq(EventInvitation.c_accepted, accepted);
        }
        final rows = await query.order(
          EventInvitation.c_createdAt,
          ascending: false,
        );
        _invitations = EventInvitation.converter(rows);
      });

  /// Invites [userId] to [eventId]. An invitation starts unanswered.
  Future<EventInvitation?> create({
    required String userId,
    required String eventId,
  }) => runQuery<EventInvitation?>(() async {
    final rows = await client.event_invitation
        .insert(EventInvitation.insert(userId: userId, eventId: eventId))
        .select();
    if (rows.isEmpty) return null;
    final created = EventInvitation.converterSingle(rows.first);
    _invitations = [created, ..._invitations];
    return created;
  });

  /// Records the answer to the invitation with [id].
  ///
  /// Returns the updated row, or `null` when the id matches no row or the
  /// request failed.
  Future<EventInvitation?> setAccepted(String id, bool accepted) =>
      runQuery<EventInvitation?>(() async {
        final rows = await client.event_invitation
            .update(EventInvitation.update(accepted: accepted))
            .eq(EventInvitation.c_id, id)
            .select();
        if (rows.isEmpty) return null;
        final updated = EventInvitation.converterSingle(rows.first);
        _invitations = [
          for (final invitation in _invitations)
            invitation.id == id ? updated : invitation,
        ];
        return updated;
      });

  /// Deletes the invitation with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.event_invitation.delete().eq(EventInvitation.c_id, id);
    _invitations = _invitations
        .where((invitation) => invitation.id != id)
        .toList();
  });
}
