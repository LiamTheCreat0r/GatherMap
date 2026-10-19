import '../models/supadart_header.dart';
import '../models/user.dart';
import '../../core/state/base_controller.dart';

/// Controller for the `user` table (profiles, not Supabase auth).
///
/// [current] is the profile the app treats as signed in. There is no auth
/// layer yet, so it is set explicitly with [setCurrent]; it becomes the
/// session's user once an auth controller exists.
class UserController extends BaseController {
  UserController({super.service});

  List<User> _users = const [];
  User? _current;

  /// Users currently held by the controller.
  List<User> get users => List.unmodifiable(_users);

  /// The profile loaded last by [fetchById], [fetchByUsername],
  /// [create] or [update].
  User? get current => _current;

  /// Sets [current] without a query — the stand-in for a signed-in session.
  ///
  /// Replaced by a real session lookup once authentication is added.
  void setCurrent(User? user) {
    _current = user;
    notifySafely();
  }

  /// Loads every profile the current RLS policies allow the client to see.
  Future<void> fetch() => runAction(() async {
    final rows = await client.user.select().order(User.c_username);
    _users = User.converter(rows);
  });

  /// Loads one profile into [current], or `null` when the id matches no row.
  Future<User?> fetchById(String id) => runQuery<User?>(() async {
    final rows = await client.user.select().eq(User.c_id, id).limit(1);
    _current = rows.isEmpty ? null : User.converterSingle(rows.first);
    return _current;
  });

  /// Loads a profile by its unique [username] into [current].
  Future<User?> fetchByUsername(String username) => runQuery<User?>(() async {
    final rows = await client.user
        .select()
        .eq(User.c_username, username)
        .limit(1);
    _current = rows.isEmpty ? null : User.converterSingle(rows.first);
    return _current;
  });

  /// Loads a profile by its unique [email] into [current].
  ///
  /// Kept separate from [fetchByUsername] so a future sign-in flow can look
  /// an account up by email without a second round trip.
  Future<User?> fetchByEmail(String email) => runQuery<User?>(() async {
    final rows = await client.user.select().eq(User.c_email, email).limit(1);
    _current = rows.isEmpty ? null : User.converterSingle(rows.first);
    return _current;
  });

  /// Inserts a profile, prepends it to [users] and returns it.
  Future<User?> create({
    required DateTime birthdate,
    required String username,
    required String name,
    required String surname,
    required String city,
    required String email,
    required String hashPassword,
    String? profilePicture,
    bool? privateAccount,
  }) => runQuery<User?>(() async {
    final rows = await client.user
        .insert(
          User.insert(
            birthdate: birthdate,
            username: username,
            name: name,
            surname: surname,
            city: city,
            email: email,
            hashPassword: hashPassword,
            profilePicture: profilePicture,
            privateAccount: privateAccount,
          ),
        )
        .select();
    if (rows.isEmpty) return null;
    final created = User.converterSingle(rows.first);
    _users = [created, ..._users];
    _current = created;
    return created;
  });

  /// Patches the profile with [id]; omitted fields keep their stored value.
  ///
  /// Returns the updated row, or `null` when the id matches no row or the
  /// request failed.
  Future<User?> update(
    String id, {
    DateTime? birthdate,
    String? username,
    String? name,
    String? surname,
    String? city,
    String? email,
    String? hashPassword,
    String? profilePicture,
    bool? privateAccount,
  }) => runQuery<User?>(() async {
    final rows = await client.user
        .update(
          User.update(
            birthdate: birthdate,
            username: username,
            name: name,
            surname: surname,
            city: city,
            email: email,
            hashPassword: hashPassword,
            profilePicture: profilePicture,
            privateAccount: privateAccount,
          ),
        )
        .eq(User.c_id, id)
        .select();
    if (rows.isEmpty) return null;
    final updated = User.converterSingle(rows.first);
    _users = [for (final user in _users) user.id == id ? updated : user];
    if (_current?.id == id) _current = updated;
    return updated;
  });

  /// Deletes the profile with [id] and drops it from the local state.
  Future<void> remove(String id) => runAction(() async {
    await client.user.delete().eq(User.c_id, id);
    _users = _users.where((user) => user.id != id).toList();
    if (_current?.id == id) _current = null;
  });
}
