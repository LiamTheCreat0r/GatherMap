import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/supabase/supabase_service.dart';
import '../../../../models/event_invitation.dart' as invitation;
import '../../../../models/supadart_header.dart';
import '../../../../models/user.dart' as row;

/// Raw `event_invitation` + `user` access for the event detail sheet.
///
/// Two queries rather than an embedded select: the invitation table and the
/// profile table are joined in [EventGuestMapper], so the generated row classes
/// never leave this layer.
class EventGuestRemoteDataSource {
  EventGuestRemoteDataSource(this._service);

  final SupabaseService _service;

  /// The Supabase client every query runs against.
  SupabaseClient get client => _service.client;

  /// Invitations addressed to [eventId], oldest first.
  Future<List<invitation.EventInvitation>> fetchInvitations(
    String eventId,
  ) async {
    final rows = await client.event_invitation
        .select()
        .eq(invitation.EventInvitation.c_eventId, eventId)
        .order(invitation.EventInvitation.c_createdAt);
    return invitation.EventInvitation.converter(rows);
  }

  /// Profiles whose ids are in [ids]. Returns an empty list for an empty input
  /// instead of issuing a query with an invalid `in` filter.
  Future<List<row.User>> fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await client.user.select().inFilter(row.User.c_id, ids);
    return row.User.converter(rows);
  }
}
