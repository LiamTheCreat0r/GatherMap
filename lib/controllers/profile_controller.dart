import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/profile.dart';
import '../models/supadart_header.dart';
import 'base_controller.dart';

/// Controller for the `profiles` table — the app-side half of an account.
///
/// Credentials live in `auth.users` and belong to `AuthController`; this
/// controller owns the public profile: the row [current] points at, and whether
/// its onboarding is finished. It follows the session through [syncSession],
/// which `main.dart` drives from the auth state with a `ProxyProvider`.
class ProfileController extends BaseController {
  ProfileController({super.service});

  List<Profile> _profiles = const [];
  Profile? _current;
  String? _sessionUserId;
  bool _loaded = false;

  /// Profiles held by the controller, in no guaranteed order.
  List<Profile> get profiles => List.unmodifiable(_profiles);

  /// The profile of the signed-in user, or `null` before it has been loaded or
  /// when the account has no row yet.
  Profile? get current => _current;

  /// True once the signed-in user's profile row has been loaded.
  bool get hasProfile => _current != null;

  /// True once a load has finished for the current session, successfully or
  /// not. Until then the gate keeps showing the splash rather than starting an
  /// onboarding flow that may be unnecessary.
  bool get isLoaded => _loaded;

  /// True once the signed-in user has been through the onboarding flow.
  bool get isOnboardingComplete => _current?.onboardingCompleted ?? false;

  /// Id of the user [current] belongs to, or `null` when signed out.
  String? get sessionUserId => _sessionUserId;

  /// Points the controller at a new signed-in user.
  ///
  /// Called on every auth change. Does nothing when the id is unchanged, clears
  /// the cache on sign-out, and otherwise loads the new profile. The work is
  /// deferred to a microtask because this runs from a provider `update`, i.e.
  /// during a build, where notifying listeners synchronously is not allowed.
  void syncSession(String? userId) {
    if (userId == _sessionUserId) return;
    _sessionUserId = userId;
    _loaded = false;

    scheduleMicrotask(() {
      // A newer session may have arrived while the microtask was queued.
      if (_sessionUserId != userId) return;
      if (userId == null) {
        _current = null;
        _profiles = const [];
        _loaded = true;
        // A failure from the session that just ended must not outlive it.
        clearError();
        notifySafely();
        return;
      }
      unawaited(loadCurrent());
    });
  }

  /// Loads the signed-in user's profile into [current].
  ///
  /// Returns `null` when signed out or when the account has no row yet — the
  /// latter is the state onboarding starts from.
  Future<Profile?> loadCurrent() async {
    final profile = await runQuery<Profile?>(() async {
      final id = _sessionUserId ?? client.auth.currentUser?.id;
      if (id == null) {
        _current = null;
        return null;
      }
      final rows = await client.profile
          .select()
          .eq(Profile.c_id, id)
          .limit(1);
      _current = rows.isEmpty ? null : Profile.converterSingle(rows.first);
      return _current;
    });

    // Reported separately from the query status: the gate needs to know the
    // attempt is over even when it failed.
    _loaded = true;
    notifySafely();
    return profile;
  }

  /// Loads every profile the current RLS policies allow the client to see.
  Future<void> fetch() => runAction(() async {
    final rows = await client.profile.select().order(Profile.c_username);
    _profiles = Profile.converter(rows);
  });

  /// Loads one profile into [current], or `null` when the id matches no row.
  Future<Profile?> fetchById(String id) => runQuery<Profile?>(() async {
    final rows = await client.profile.select().eq(Profile.c_id, id).limit(1);
    _current = rows.isEmpty ? null : Profile.converterSingle(rows.first);
    return _current;
  });

  /// Loads a profile by its unique [username] into [current].
  Future<Profile?> fetchByUsername(String username) =>
      runQuery<Profile?>(() async {
        final rows = await client.profile
            .select()
            .eq(Profile.c_username, username)
            .limit(1);
        _current = rows.isEmpty ? null : Profile.converterSingle(rows.first);
        return _current;
      });

  /// True while nothing occupies [username].
  ///
  /// A "no" here is not a reservation: two people can pass this check at the
  /// same moment, and the unique constraint on the column is what actually
  /// decides. Onboarding treats that failure (`23505`) as "already taken".
  Future<bool> isUsernameAvailable(String username) async {
    final free = await runQuery<bool>(() async {
      final rows = await client.profile
          .select(Profile.c_id)
          .eq(Profile.c_username, username)
          .limit(1);
      return rows.isEmpty;
    });
    return free ?? false;
  }

  /// Writes the onboarding answers and marks the profile complete.
  ///
  /// Updates the signed-in user's row; if there is none (a project where the
  /// `on_auth_user_created` trigger was never installed) it inserts one, which
  /// the "profiles_insert_own" policy allows.
  Future<Profile?> completeOnboarding({
    required String username,
    required String name,
    required String surname,
    required DateTime birthdate,
    required String city,
    bool privateAccount = false,
  }) => runQuery<Profile?>(() async {
    final id = client.auth.currentUser?.id;
    if (id == null) return null;

    final values = Profile.update(
      username: username,
      name: name,
      surname: surname,
      birthdate: birthdate,
      city: city,
      privateAccount: privateAccount,
      onboardingCompleted: true,
    );

    var rows = await client.profile.update(values).eq(Profile.c_id, id).select();
    if (rows.isEmpty) {
      rows = await client.profile
          .insert({Profile.c_id: id, ...values})
          .select();
    }
    if (rows.isEmpty) return null;

    _current = Profile.converterSingle(rows.first);
    return _current;
  });

  /// Patches the profile with [id]; omitted fields keep their stored value.
  ///
  /// Returns the updated row, or `null` when the id matches no row or the
  /// request failed.
  Future<Profile?> update(
    String id, {
    String? username,
    String? name,
    String? surname,
    DateTime? birthdate,
    String? city,
    String? profilePicture,
    bool? privateAccount,
    bool? onboardingCompleted,
  }) => runQuery<Profile?>(() async {
    final rows = await client.profile
        .update(
          Profile.update(
            username: username,
            name: name,
            surname: surname,
            birthdate: birthdate,
            city: city,
            profilePicture: profilePicture,
            privateAccount: privateAccount,
            onboardingCompleted: onboardingCompleted,
          ),
        )
        .eq(Profile.c_id, id)
        .select();
    if (rows.isEmpty) return null;
    final updated = Profile.converterSingle(rows.first);
    _profiles = [
      for (final profile in _profiles) profile.id == id ? updated : profile,
    ];
    if (_current?.id == id) _current = updated;
    return updated;
  });

  /// Sets [current] without a query, for tests and for callers that already
  /// hold the row.
  @visibleForTesting
  void setCurrent(Profile? profile) {
    _current = profile;
    _loaded = true;
    notifySafely();
  }
}
