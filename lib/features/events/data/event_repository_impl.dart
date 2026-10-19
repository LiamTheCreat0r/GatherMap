import '../../../../models/event.dart' as row;
import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'event_mapper.dart';
import 'event_remote_data_source.dart';

/// [EventRepository] backed by the Supabase `event` table.
///
/// Translates the domain contract into data-source calls and maps the rows
/// back through [EventMapper]. It never throws on its own: a failed query
/// surfaces as whatever the client raised, for the presentation layer to
/// turn into a message via `describeError`.
class SupabaseEventRepository implements EventRepository {
  SupabaseEventRepository(this._source, this._mapper);

  final EventRemoteDataSource _source;
  final EventMapper _mapper;

  @override
  Future<List<Event>> fetch({EventScope scope = EventScope.all}) async {
    final rows = await _source.fetchRows(scope: scope);
    return [for (final row in rows) _mapper.toEntity(row)];
  }

  @override
  Future<Event?> fetchById(String id) async {
    final rows = await _source.fetchRowsById(id);
    return rows.isEmpty ? null : _mapper.toEntity(rows.first);
  }

  @override
  Future<Event> create(NewEvent draft) async {
    final rows = await _source.insertRows(_mapper.toInsert(draft));
    return _mapper.toEntity(rows.first);
  }

  @override
  Future<Event?> update(String id, EventPatch patch) async {
    final rows = await _source.updateRows(id, _mapper.toUpdate(patch));
    return rows.isEmpty ? null : _mapper.toEntity(rows.first);
  }

  @override
  Future<void> delete(String id) => _source.deleteRow(id);

  @override
  Stream<List<Event>> watch() {
    return _source.watchRows().map(
      (rows) => [
        for (final json in rows) _mapper.toEntity(row.Event.fromJson(json)),
      ],
    );
  }
}
