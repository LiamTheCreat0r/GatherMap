import 'package:flutter/material.dart';

/// Central route table for the app.
///
/// Detail routes listed in [hiddenNavRoutes] push on top of the navigation
/// shell and must hide the bottom navigation bar while they are visible.
class AppRoutes {
  AppRoutes._();

  // Tab routes — the bottom navigation stays visible on these.
  static const String events = '/events';
  static const String map = '/map';
  static const String messages = '/messages';
  static const String profile = '/profile';

  // Detail routes — the bottom navigation is hidden on these.
  static const String eventDetail = '/events/:id';

  // Auth routes — pushed over the gate, never inside the navigation shell.
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  /// Route name patterns where the bottom navigation must be hidden.
  ///
  /// Add a pattern here (for example `'/settings/edit'`) and the navigation
  /// bar will automatically disappear while that route is on top.
  static const List<String> hiddenNavRoutes = [eventDetail];

  /// Builds the routes that are pushed by name.
  ///
  /// The four tab pages are hosted directly by the navigation shell and are not
  /// pushed, and the auth screens are opened with their own [MaterialPageRoute]
  /// from the login page, so this handles the detail routes only.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (isNavHidden(settings.name)) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const EventDetailPlaceholder(),
      );
    }
    return null;
  }

  /// Returns true when the bottom navigation should be hidden for [name].
  static bool isNavHidden(String? name) {
    if (name == null || name.isEmpty) return false;
    return hiddenNavRoutes.any((pattern) => _matches(pattern, name));
  }

  /// Matches a pattern such as `/events/:id` against a concrete name such as
  /// `/events/42`. Segments starting with `:` act as wildcards.
  static bool _matches(String pattern, String name) {
    final patternSegments = pattern.split('/');
    final nameSegments = name.split('/');
    if (patternSegments.length != nameSegments.length) return false;
    for (var i = 0; i < patternSegments.length; i++) {
      final segment = patternSegments[i];
      if (segment.startsWith(':')) continue;
      if (segment != nameSegments[i]) return false;
    }
    return true;
  }
}

/// Holds the name of the route currently on top of the navigator.
///
/// The navigation shell listens to this so it can hide itself as soon as a
/// detail route is pushed and show itself again once it is popped.
class CurrentRoute {
  CurrentRoute._();

  static final ValueNotifier<String?> name = ValueNotifier<String?>(null);
}

/// Shared observer instance for `MaterialApp.navigatorObservers`.
final CurrentRouteObserver currentRouteObserver = CurrentRouteObserver();

/// Keeps [CurrentRoute.name] in sync with the navigator's top route.
///
/// Register on `MaterialApp.navigatorObservers`.
class CurrentRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CurrentRoute.name.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CurrentRoute.name.value = previousRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CurrentRoute.name.value = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    CurrentRoute.name.value = newRoute?.settings.name;
  }
}

/// Stand-in for the real event detail screen.
///
/// Its only job right now is to prove that pushing a detail route hides the
/// bottom navigation bar, and popping it brings the bar back.
class EventDetailPlaceholder extends StatelessWidget {
  const EventDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Event details')));
  }
}
