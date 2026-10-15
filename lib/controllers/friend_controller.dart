import '../models/friend.dart';
import '../models/supadart_header.dart';
import 'base_controller.dart';

/// Controller for the `friend` table.
///
/// Friendship is a single row holding both sides (`user_id_1`, `user_id_2`),
/// so [fetchForUser] matches either column and [remove] deletes the pair by
/// its row id.
class FriendController extends BaseController {
  FriendController({super.service});

  List<Friend> _friends = const [];

  /// Friend rows currently held by the controller.
  List<Friend> get friends => List.unmodifiable(_friends);

  /// Loads every friendship of [userId], newest first.
  Future<void> fetchForUser(String userId) => runAction(() async {
    final rows = await client.friend
        .select()
        .or('${Friend.c_userId1}.eq.$userId,${Friend.c_userId2}.eq.$userId')
        .order(Friend.c_friendsSince, ascending: false);
    _friends = Friend.converter(rows);
  });

  /// Creates the friendship row between [userId1] and [userId2].
  Future<Friend?> add({required String userId1, required String userId2}) =>
      runQuery<Friend?>(() async {
        final rows = await client.friend
            .insert(Friend.insert(userId1: userId1, userId2: userId2))
            .select();
        if (rows.isEmpty) return null;
        final created = Friend.converterSingle(rows.first);
        _friends = [created, ..._friends];
        return created;
      });

  /// Deletes the friendship with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.friend.delete().eq(Friend.c_id, id);
    _friends = _friends.where((friend) => friend.id != id).toList();
  });
}
