import '../models/chat.dart';
import '../models/supadart_header.dart';
import 'base_controller.dart';

/// Controller for the `chat` table.
///
/// A chat is attached to at most one thing: a circle, an event or a pair of
/// friends. The `ensure*` helpers return the existing chat for that target
/// and create it on first use, which is what screens should call instead of
/// inserting blindly.
class ChatController extends BaseController {
  ChatController({super.service});

  List<Chat> _chats = const [];
  Chat? _current;

  /// Chats currently held by the controller.
  List<Chat> get chats => List.unmodifiable(_chats);

  /// The chat loaded last by [fetchById], [ensure*] or [create].
  Chat? get current => _current;

  /// Loads every chat the current RLS policies allow the client to see.
  Future<void> fetchAll() => runAction(() async {
    final rows = await client.chat.select().order(Chat.c_id);
    _chats = Chat.converter(rows);
  });

  /// Loads one chat into [current], or `null` when the id matches no row.
  Future<Chat?> fetchById(String id) => runQuery<Chat?>(() async {
    final rows = await client.chat.select().eq(Chat.c_id, id).limit(1);
    _current = rows.isEmpty ? null : Chat.converterSingle(rows.first);
    return _current;
  });

  /// Returns the chat attached to [eventId], creating it when missing.
  Future<Chat?> ensureForEvent(String eventId) =>
      _ensure(Chat.c_eventId, eventId, () => Chat.insert(eventId: eventId));

  /// Returns the chat attached to [circleId], creating it when missing.
  Future<Chat?> ensureForCircle(String circleId) =>
      _ensure(Chat.c_circleId, circleId, () => Chat.insert(circleId: circleId));

  /// Returns the chat attached to [friendId], creating it when missing.
  Future<Chat?> ensureForFriend(String friendId) =>
      _ensure(Chat.c_friendId, friendId, () => Chat.insert(friendId: friendId));

  /// Inserts a chat directly, for a target that is not one of the `ensure*`
  /// cases (or when the caller already knows no chat exists).
  Future<Chat?> create({String? circleId, String? eventId, String? friendId}) =>
      runQuery<Chat?>(() async {
        final rows = await client.chat
            .insert(
              Chat.insert(
                circleId: circleId,
                eventId: eventId,
                friendId: friendId,
              ),
            )
            .select();
        if (rows.isEmpty) return null;
        final created = Chat.converterSingle(rows.first);
        _chats = [created, ..._chats];
        _current = created;
        return created;
      });

  /// Deletes the chat with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.chat.delete().eq(Chat.c_id, id);
    _chats = _chats.where((chat) => chat.id != id).toList();
    if (_current?.id == id) _current = null;
  });

  /// Follows the whole `chat` table over realtime.
  void watch() {
    watchTable(
      client.chat.stream(primaryKey: [Chat.c_id]),
      onData: (rows) => _chats = Chat.converter(rows),
    );
  }

  /// Finds the chat whose [column] equals [value], creating it with
  /// [buildInsert] when the query comes back empty.
  Future<Chat?> _ensure(
    String column,
    String value,
    Map<String, dynamic> Function() buildInsert,
  ) => runQuery<Chat?>(() async {
    final rows = await client.chat.select().eq(column, value).limit(1);
    if (rows.isNotEmpty) {
      final chat = Chat.converterSingle(rows.first);
      _current = chat;
      if (!_chats.any((existing) => existing.id == chat.id)) {
        _chats = [chat, ..._chats];
      }
      return chat;
    }
    final inserted = await client.chat.insert(buildInsert()).select();
    if (inserted.isEmpty) return null;
    final chat = Chat.converterSingle(inserted.first);
    _chats = [chat, ..._chats];
    _current = chat;
    return chat;
  });
}
