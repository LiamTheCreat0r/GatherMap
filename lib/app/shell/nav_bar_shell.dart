import 'package:flutter/material.dart';
import 'package:gathermap/features/chats/presentation/chat_page.dart';
import 'package:gathermap/features/profile/presentation/account_page.dart';

import '../../core/routing/app_routes.dart';
import '../../features/events/presentation/events_list.dart';
import '../../features/map/presentation/map_page.dart';
import 'navbar.dart';

/// Hosts the four tab pages and the bottom navigation bar.
///
/// Pages are held in an [IndexedStack] so each tab keeps its own state
/// (scroll position, form input, …) when the user switches away and back.
///
/// A tab is only built once it has been visited. [IndexedStack] keeps its
/// children alive, but it also builds *all* of them up front — which would
/// spin up the native MapLibre platform view on the first frame even though
/// the Events tab is what the user sees. That platform-view startup stalls
/// the main thread long enough to trip an ANR. Deferring the map until its
/// tab is opened moves that cost off the launch path while still preserving
/// the map's state on later switches.
///
/// The navigation bar is hidden whenever the top route matches one of
/// [AppRoutes.hiddenNavRoutes] — currently the event detail screen. Because
/// visibility is driven by [CurrentRoute], any detail screen that pushes a
/// named route automatically hides the bar with no extra wiring.
class NavBarShell extends StatefulWidget {
  const NavBarShell({super.key});

  @override
  State<NavBarShell> createState() => _NavBarShellState();
}

class _NavBarShellState extends State<NavBarShell> {
  int _currentIndex = 0;

  /// Tabs that have been shown at least once, and so should be built.
  final Set<int> _visited = {0};

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _visited.add(index);
      _currentIndex = index;
    });
  }

  /// The four tab pages, with unvisited tabs replaced by a cheap placeholder.
  ///
  /// Once a tab is in [_visited] it is built normally, and [IndexedStack]
  /// keeps its element (and state) alive across later switches.
  List<Widget> _pages() => [
    const EventsList(),
    _visited.contains(1) ? const MapPage() : const SizedBox.shrink(),
    _visited.contains(2) ? const ChatPage() : const SizedBox.shrink(),
    _visited.contains(3) ? const AccountPage() : const SizedBox.shrink(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: CurrentRoute.name,
      builder: (context, routeName, _) {
        final showNav = !AppRoutes.isNavHidden(routeName);

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages()),
          bottomNavigationBar: showNav
              ? Navbar(currentIndex: _currentIndex, onTap: _onTap)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
