import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/supabase/supabase_service.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/chats/presentation/chat_controller.dart';
import '../../features/chats/presentation/message_controller.dart';
import '../../features/circles/presentation/circle_controller.dart';
import '../../features/circles/presentation/circle_member_controller.dart';
import '../../features/events/data/address_service.dart';
import '../../features/events/data/event_mapper.dart';
import '../../features/events/data/event_remote_data_source.dart';
import '../../features/events/data/event_repository_impl.dart';
import '../../features/events/domain/address_search.dart';
import '../../features/events/domain/event_repository.dart';
import '../../features/events/presentation/event_controller.dart';
import '../../features/invitations/presentation/event_invitation_controller.dart';
import '../../features/friends/presentation/blocked_user_controller.dart';
import '../../features/friends/presentation/friend_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';

/// The concrete implementations the app runs against.
///
/// Constructing this wires object graphs together but performs no I/O: the
/// [SupabaseService] resolves its client on first query, so the whole app can
/// be assembled before `Supabase.initialize` runs (and in tests, where it
/// never runs).
class AppDependencies {
  AppDependencies({SupabaseService? service})
    : _service = service ?? SupabaseService() {
    eventRepository = SupabaseEventRepository(
      EventRemoteDataSource(_service),
      const EventMapper(),
    );
  }

  final SupabaseService _service;

  /// The events feature's data contract, implemented over Supabase.
  late final EventRepository eventRepository;

  /// Geocoder used by the create-event form.
  late final AddressSearch addressSearch = AddressService();
}

/// Wraps [child] in the provider scope the app expects.
///
/// `create` is lazy: a controller is only built when a widget first reads it,
/// so nothing is constructed at startup beyond the dependency graph itself.
Widget buildProviderScope({
  required Widget child,
  AppDependencies? dependencies,
}) {
  final deps = dependencies ?? AppDependencies();

  return MultiProvider(
    providers: [
      Provider<AddressSearch>.value(value: deps.addressSearch),
      ChangeNotifierProvider(create: (_) => AuthController()),

      // The profile cache is not per-table: it follows the session, so it is a
      // proxy over AuthController — `syncSession` loads the row on a sign-in
      // and clears it on a sign-out. `AuthGate` is what calls
      // `AuthController.initialize` to restore the persisted session.
      ChangeNotifierProxyProvider<AuthController, ProfileController>(
        create: (_) => ProfileController(),
        update: (_, auth, profile) => profile!..syncSession(auth.userId),
      ),

      ChangeNotifierProvider(
        create: (_) => EventController(deps.eventRepository),
      ),
      ChangeNotifierProvider(create: (_) => EventInvitationController()),
      ChangeNotifierProvider(create: (_) => CircleController()),
      ChangeNotifierProvider(create: (_) => CircleMemberController()),
      ChangeNotifierProvider(create: (_) => ChatController()),
      ChangeNotifierProvider(create: (_) => MessageController()),
      ChangeNotifierProvider(create: (_) => FriendController()),
      ChangeNotifierProvider(create: (_) => BlockedUserController()),
    ],
    child: child,
  );
}
