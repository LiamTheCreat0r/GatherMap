import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/di/providers.dart';
import 'package:gathermap/core/state/base_controller.dart';
import 'package:gathermap/features/auth/presentation/auth_controller.dart';
import 'package:gathermap/features/events/domain/event.dart';
import 'package:gathermap/features/events/domain/event_repository.dart';
import 'package:gathermap/features/events/presentation/event_controller.dart';
import 'package:gathermap/features/profile/presentation/profile_controller.dart';

/// An [EventRepository] that fails the test if anything is asked of it.
///
/// Constructing a controller must never touch the network, so every method
/// throws rather than returning a neutral value.
class _UntouchableEventRepository implements EventRepository {
  Never _untouchable() =>
      fail('the repository was called during construction');

  @override
  Future<List<Event>> fetch({EventScope scope = EventScope.all}) async =>
      _untouchable();

  @override
  Future<Event?> fetchById(String id) async => _untouchable();

  @override
  Future<Event> create(NewEvent draft) async => _untouchable();

  @override
  Future<Event?> update(String id, EventPatch patch) async => _untouchable();

  @override
  Future<void> delete(String id) async => _untouchable();

  @override
  Stream<List<Event>> watch() => _untouchable();
}

/// Building the provider graph must not touch `Supabase.instance`: the service
/// resolves its client lazily, so the whole layer can be assembled before
/// `Supabase.initialize` runs (and in tests, where it never runs).
void main() {
  testWidgets('buildProviderScope mounts without a Supabase client', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProviderScope(child: const MaterialApp(home: SizedBox.shrink())),
    );

    expect(tester.takeException(), isNull);
  });

  test('the dependency graph builds without touching the network', () {
    final dependencies = AppDependencies();

    expect(dependencies.eventRepository, isNotNull);
  });

  test('a controller can be built without a Supabase client', () {
    final controller = EventController(_UntouchableEventRepository());
    addTearDown(controller.dispose);

    expect(controller.status, ControllerStatus.idle);
    expect(controller.error, isNull);
    expect(controller.events, isEmpty);
  });

  test('the session controllers build without a Supabase client', () {
    // `AuthController` holds the session and `ProfileController` follows it;
    // reading either at construction time would reach for the global client
    // before `Supabase.initialize` has run (and in tests, where it never
    // does). `AuthGate` is what calls `initialize()`.
    final auth = AuthController();
    final profile = ProfileController();
    addTearDown(auth.dispose);
    addTearDown(profile.dispose);

    expect(auth.isInitialized, isFalse);
    expect(auth.isSignedIn, isFalse);
    expect(auth.status, ControllerStatus.idle);
    expect(profile.current, isNull);
    expect(profile.isLoaded, isFalse);
  });
}
