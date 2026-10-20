import '../domain/event_guest.dart';
import '../domain/event_guest_repository.dart';
import 'event_guest_mapper.dart';
import 'event_guest_remote_data_source.dart';

/// [EventGuestRepository] backed by the Supabase `event_invitation` and `user`
/// tables.
class SupabaseEventGuestRepository implements EventGuestRepository {
  SupabaseEventGuestRepository(this._source, this._mapper);

  final EventGuestRemoteDataSource _source;
  final EventGuestMapper _mapper;

  @override
  Future<EventGuestBook> fetchForEvent(
    String eventId, {
    required String ownerId,
  }) async {
    final invitations = await _source.fetchInvitations(eventId);

    final ids = <String>{
      if (ownerId.isNotEmpty) ownerId,
      for (final invitation in invitations)
        if (invitation.userId.isNotEmpty) invitation.userId,
    }.toList();

    final users = await _source.fetchUsersByIds(ids);

    return _mapper.toBook(
      invitations: invitations,
      users: users,
      ownerId: ownerId,
    );
  }
}
