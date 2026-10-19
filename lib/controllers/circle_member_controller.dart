import '../models/circle_member.dart';
import '../models/supadart_header.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `circle_member` table (the join between circles and
/// the users in them).
class CircleMemberController extends BaseController {
  CircleMemberController({super.service});

  List<CircleMember> _members = const [];

  /// Members currently held by the controller.
  List<CircleMember> get members => List.unmodifiable(_members);

  /// Loads everyone in [circleId], oldest join first.
  Future<void> fetchForCircle(String circleId) => runAction(() async {
    final rows = await client.circle_member
        .select()
        .eq(CircleMember.c_circleId, circleId)
        .order(CircleMember.c_createdAt);
    _members = CircleMember.converter(rows);
  });

  /// Loads every circle [userId] belongs to.
  Future<void> fetchForUser(String userId) => runAction(() async {
    final rows = await client.circle_member
        .select()
        .eq(CircleMember.c_userId, userId)
        .order(CircleMember.c_createdAt);
    _members = CircleMember.converter(rows);
  });

  /// Adds [userId] to [circleId], optionally with a display [nickname].
  Future<CircleMember?> add({
    required String userId,
    required String circleId,
    String? nickname,
  }) => runQuery<CircleMember?>(() async {
    final rows = await client.circle_member
        .insert(
          CircleMember.insert(
            userId: userId,
            circleId: circleId,
            userNickname: nickname,
          ),
        )
        .select();
    if (rows.isEmpty) return null;
    final created = CircleMember.converterSingle(rows.first);
    _members = [created, ..._members];
    return created;
  });

  /// Renames the member row with [id]; passing `null` clears the nickname.
  Future<CircleMember?> setNickname(String id, String? nickname) =>
      runQuery<CircleMember?>(() async {
        final rows = await client.circle_member
            .update(CircleMember.update(userNickname: nickname))
            .eq(CircleMember.c_id, id)
            .select();
        if (rows.isEmpty) return null;
        final updated = CircleMember.converterSingle(rows.first);
        _members = [
          for (final member in _members) member.id == id ? updated : member,
        ];
        return updated;
      });

  /// Removes the member row with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.circle_member.delete().eq(CircleMember.c_id, id);
    _members = _members.where((member) => member.id != id).toList();
  });
}
