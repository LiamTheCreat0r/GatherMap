import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/supabase/supabase_service.dart';
import '../../../../models/event_invitation.dart' as invitation;
import '../../../../models/profile.dart' as row;
import '../../../../models/supadart_header.dart';

/// Raw `event_invitation` + `profiles` access for the event detail sheet.
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
  Future<List<row.Profile>> fetchProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await client.profile.select().inFilter(row.Profile.c_id, ids);
    return row.Profile.converter(rows);
  }
}
