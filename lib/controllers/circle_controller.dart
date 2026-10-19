import '../models/circle.dart';
import '../models/supadart_header.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `circle` table.
///
/// A circle only knows its [Circle.ownerId]; membership lives in
/// `circle_member` and is handled by `CircleMemberController`.
class CircleController extends BaseController {
  CircleController({super.service});

  List<Circle> _circles = const [];
  Circle? _selected;

  /// Circles currently held by the controller.
  List<Circle> get circles => List.unmodifiable(_circles);

  /// The circle loaded last by [fetchById], [create] or [remove].
  Circle? get selected => _selected;

  /// Loads the circles created by [ownerId].
  Future<void> fetchOwnedBy(String ownerId) => runAction(() async {
    final rows = await client.circle
        .select()
        .eq(Circle.c_ownerId, ownerId)
        .order(Circle.c_createdAt, ascending: false);
    _circles = Circle.converter(rows);
  });

  /// Loads one circle into [selected], or `null` when the id matches no row.
  Future<Circle?> fetchById(String id) => runQuery<Circle?>(() async {
    final rows = await client.circle.select().eq(Circle.c_id, id).limit(1);
    _selected = rows.isEmpty ? null : Circle.converterSingle(rows.first);
    return _selected;
  });

  /// Creates a circle owned by [ownerId], prepends it to [circles] and
  /// returns it.
  Future<Circle?> create({required String ownerId}) =>
      runQuery<Circle?>(() async {
        final rows = await client.circle
            .insert(Circle.insert(ownerId: ownerId))
            .select();
        if (rows.isEmpty) return null;
        final created = Circle.converterSingle(rows.first);
        _circles = [created, ..._circles];
        _selected = created;
        return created;
      });

  /// Deletes the circle with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.circle.delete().eq(Circle.c_id, id);
    _circles = _circles.where((circle) => circle.id != id).toList();
    if (_selected?.id == id) _selected = null;
  });
}
