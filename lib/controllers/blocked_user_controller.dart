import '../models/blocked_user.dart';
import '../models/supadart_header.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `blocked_user` table.
///
/// A block is the row `(blocker_id, blocked_id)`: the user who blocked, and
/// the user who was blocked.
class BlockedUserController extends BaseController {
  BlockedUserController({super.service});

  List<BlockedUser> _blocked = const [];

  /// Block rows currently held by the controller.
  List<BlockedUser> get blocked => List.unmodifiable(_blocked);

  /// Loads everyone [blockerId] has blocked, most recent first.
  Future<void> fetchForBlocker(String blockerId) => runAction(() async {
    final rows = await client.blocked_user
        .select()
        .eq(BlockedUser.c_blockerId, blockerId)
        .order(BlockedUser.c_blockedAt, ascending: false);
    _blocked = BlockedUser.converter(rows);
  });

  /// Blocks [blockedId] on behalf of [blockerId] and returns the row.
  Future<BlockedUser?> block({
    required String blockerId,
    required String blockedId,
  }) => runQuery<BlockedUser?>(() async {
    final rows = await client.blocked_user
        .insert(BlockedUser.insert(blockerId: blockerId, blockedId: blockedId))
        .select();
    if (rows.isEmpty) return null;
    final created = BlockedUser.converterSingle(rows.first);
    _blocked = [created, ..._blocked];
    return created;
  });

  /// Deletes the block with [id] and drops it from the local state.
  Future<void> unblock(String id) => runAction(() async {
    await client.blocked_user.delete().eq(BlockedUser.c_id, id);
    _blocked = _blocked.where((block) => block.id != id).toList();
  });

  /// Whether [blockerId] has already blocked [blockedId].
  ///
  /// Runs its own query so the answer stays correct even when [blocked] has
  /// not been loaded; returns `false` on failure and records it in [error].
  Future<bool> hasBlocked({
    required String blockerId,
    required String blockedId,
  }) async {
    final rows = await runQuery(
      () => client.blocked_user
          .select()
          .eq(BlockedUser.c_blockerId, blockerId)
          .eq(BlockedUser.c_blockedId, blockedId)
          .limit(1),
    );
    return rows?.isNotEmpty ?? false;
  }
}
