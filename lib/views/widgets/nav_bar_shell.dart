import 'package:flutter/material.dart';

import '../../core/route.dart';
import '../events_list.dart';
import '../test_page_2.dart';
import 'map.dart';
import '../test_page_3.dart';
import '../test_page_4.dart';
import 'navbar.dart';

/// Hosts the four tab pages and the bottom navigation bar.
///
/// Pages are held in an [IndexedStack] so each tab keeps its own state
/// (scroll position, form input, …) when the user switches away and back.
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

  static const List<Widget> _pages = [
    EventsList(),
    Map(),
    TestPage3(),
    TestPage4(),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: CurrentRoute.name,
      builder: (context, routeName, _) {
        final showNav = !AppRoutes.isNavHidden(routeName);

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: showNav
              ? Navbar(currentIndex: _currentIndex, onTap: _onTap)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
