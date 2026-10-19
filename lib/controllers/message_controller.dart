import '../models/message.dart';
import '../models/supadart_header.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `message` table.
///
/// Holds the thread of a single chat at a time: [fetchForChat] and
/// [watchForChat] replace the loaded rows, and [clear] empties them when the
/// screen moves to another conversation.
class MessageController extends BaseController {
  MessageController({super.service});

  List<Message> _messages = const [];
  String? _chatId;

  /// Messages of the loaded conversation, oldest first.
  List<Message> get messages => List.unmodifiable(_messages);

  /// The chat the loaded messages belong to, if any.
  String? get chatId => _chatId;

  /// Loads the last [limit] messages of [chatId], oldest first.
  ///
  /// The database returns them newest first so the limit picks the most
  /// recent ones; they are reversed locally for chronological rendering.
  Future<void> fetchForChat(String chatId, {int limit = 50}) =>
      runAction(() async {
        final rows = await client.message
            .select()
            .eq(Message.c_chatId, chatId)
            .order(Message.c_createdAt, ascending: false)
            .limit(limit);
        _chatId = chatId;
        _messages = Message.converter(rows).reversed.toList();
      });

  /// Follows [chatId] over realtime: initial fetch plus live updates.
  void watchForChat(String chatId) {
    _chatId = chatId;
    watchTable(
      client.message
          .stream(primaryKey: [Message.c_id])
          .eq(Message.c_chatId, chatId)
          .order(Message.c_createdAt),
      onData: (rows) => _messages = Message.converter(rows),
    );
  }

  /// Sends [content] (or an [image] URL) from [senderId] into [chatId] and
  /// appends it to [messages].
  ///
  /// `created_at` is left to the database default so the row carries the
  /// server's timestamp.
  Future<Message?> send({
    required String chatId,
    required String senderId,
    String? content,
    String? image,
  }) => runQuery<Message?>(() async {
    final rows = await client.message
        .insert(
          Message.insert(
            content: content,
            image: image,
            senderId: senderId,
            chatId: chatId,
          ),
        )
        .select();
    if (rows.isEmpty) return null;
    final sent = Message.converterSingle(rows.first);
    _chatId = chatId;
    _messages = [..._messages, sent];
    return sent;
  });

  /// Empties the loaded thread — call when leaving a conversation.
  void clear() {
    _messages = const [];
    _chatId = null;
    notifySafely();
  }
}
