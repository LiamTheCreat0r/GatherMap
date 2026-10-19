import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/supabase/supabase_service.dart';
import '../../../../models/event.dart' as row;
import '../../../../models/supadart_header.dart';
import '../domain/event_repository.dart';

/// Raw `event` table access over Supabase.
///
/// Owns every query the feature runs and returns generated row objects; it
/// knows nothing about the domain [Event] and exposes no state. Constructed
/// with an injectable [SupabaseService] so tests can point it anywhere.
class EventRemoteDataSource {
  EventRemoteDataSource(this._service);

  final SupabaseService _service;

  /// The Supabase client every query runs against.
  SupabaseClient get client => _service.client;

  /// Rows matching [scope], sorted as described on [EventScope].
  Future<List<row.Event>> fetchRows({
    EventScope scope = EventScope.all,
  }) async {
    switch (scope) {
      case EventScope.all:
        return row.Event.converter(
          await client.event.select().order(
            row.Event.c_scheduledAt,
            ascending: false,
          ),
        );
      case EventScope.upcoming:
        return row.Event.converter(
          await client.event
              .select()
              .gte(row.Event.c_scheduledAt, _nowUtc())
              .order(row.Event.c_scheduledAt),
        );
      case EventScope.past:
        return row.Event.converter(
          await client.event
              .select()
              .lt(row.Event.c_scheduledAt, _nowUtc())
              .order(row.Event.c_scheduledAt, ascending: false),
        );
    }
  }

  /// One row, or an empty list when the id matches nothing.
  Future<List<row.Event>> fetchRowsById(String id) async {
    return row.Event.converter(
      await client.event.select().eq(row.Event.c_id, id).limit(1),
    );
  }

  /// Inserts [payload] and returns the row as stored by the database.
  Future<List<row.Event>> insertRows(Map<String, dynamic> payload) async {
    return row.Event.converter(await client.event.insert(payload).select());
  }

  /// Patches the row with [id] and returns it, or an empty list when the id
  /// matches nothing.
  Future<List<row.Event>> updateRows(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return row.Event.converter(
      await client.event.update(payload).eq(row.Event.c_id, id).select(),
    );
  }

  /// Deletes the row with [id].
  Future<void> deleteRow(String id) async {
    await client.event.delete().eq(row.Event.c_id, id);
  }

  /// Realtime stream of the whole table, newest first.
  ///
  /// Emits raw row maps so the repository can convert them.
  Stream<List<Map<String, dynamic>>> watchRows() {
    return client.event
        .stream(primaryKey: [row.Event.c_id])
        .order(row.Event.c_scheduledAt, ascending: false);
  }

  /// Current instant in the UTC form PostgREST expects for comparisons.
  static String _nowUtc() => DateTime.now().toUtc().toIso8601String();
}
