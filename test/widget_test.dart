// Basic widget tests for the app's navbar shell.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:gathermap/core/route.dart';
import 'package:gathermap/main.dart';
import 'package:gathermap/views/widgets/navbar.dart';
import 'package:gathermap/views/widgets/nav_bar_shell.dart';

/// A no-op MapLibre platform used while the navbar shell is under test.
///
/// [NavBarShell] keeps every tab alive in an [IndexedStack], so the Map tab —
/// and therefore [MapLibreMap] — is built even in tests that never touch it.
/// A real map only initializes its method channel once a platform view is
/// created, which never happens in widget tests; disposing it then throws a
/// `LateInitializationError`. Returning an inert widget and skipping disposal
/// keeps the plugin out of the way without changing production code.
class _FakeMapLibrePlatform extends MapLibreMethodChannel {
  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    return const SizedBox.shrink();
  }

  // The real implementation dereferences the method channel, which is never
  // initialized without a platform view.
  @override
  // ignore: must_call_super
  void dispose() {}
}

void main() {
  final originalCreateInstance = MapLibrePlatform.createInstance;

  setUp(() {
    // Each test starts with the bar visible.
    CurrentRoute.name.value = null;
    // Keep the map plugin from creating (and later disposing) a platform view.
    MapLibrePlatform.createInstance = () => _FakeMapLibrePlatform();
  });

  tearDown(() {
    MapLibrePlatform.createInstance = originalCreateInstance;
  });

  testWidgets('App renders navbar with four icon-only tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(Navbar), findsOneWidget);
    expect(find.byType(NavBarShell), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(4));

    // Icon-only: no Material tabs and no text labels anywhere.
    expect(find.byType(Tab), findsNothing);
    for (final tab in NavTab.values) {
      expect(find.text(tab.label), findsNothing);
    }
  });

  testWidgets('Active tab is orange and inactive tabs are warm gray',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();

    final activeFilter = pictures.first.colorFilter;
    final inactiveFilter = pictures.last.colorFilter;

    expect(
      activeFilter,
      const ColorFilter.mode(Color.fromARGB(255, 242, 100, 25), BlendMode.srcIn),
    );
    expect(
      inactiveFilter,
      const ColorFilter.mode(
          Color.fromARGB(255, 154, 143, 131), BlendMode.srcIn),
    );
  });

  testWidgets('Tapping a tab changes the active index', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap the Map tab (index 1).
    await tester.tap(find.byType(SvgPicture).at(1));
    await tester.pumpAndSettle();

    final navbar = tester.widget<Navbar>(find.byType(Navbar));
    expect(navbar.currentIndex, 1);

    // Tap the Profile tab (index 3).
    await tester.tap(find.byType(SvgPicture).at(3));
    await tester.pumpAndSettle();

    expect(tester.widget<Navbar>(find.byType(Navbar)).currentIndex, 3);
  });

  testWidgets('Detail route hides the navbar, popping restores it',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(Navbar), findsOneWidget);

    // Push a named event detail route.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.eventDetail.replaceAll(':id', '42'));
    await tester.pumpAndSettle();

    expect(find.byType(Navbar), findsNothing);
    expect(find.text('Event details'), findsOneWidget);

    // Pop back to the shell.
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(Navbar), findsOneWidget);
  });

  testWidgets('Navbar spans the full width as a short bar at the bottom',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(find.byType(Navbar));
    final topLeft = box.localToGlobal(Offset.zero);
    final screen = tester.getSize(find.byType(MaterialApp));

    // Full width, flush left.
    expect(box.size.width, screen.width);
    expect(topLeft.dx, 0);

    // A bar, not a screen-height block: 24px icon + 12px padding either side.
    expect(box.size.height, 48);

    // Pinned to the bottom edge.
    expect(topLeft.dy + box.size.height, screen.height);

    // The four icons sit at the centre of four equal quarters, so their
    // centres are evenly spaced by a quarter of the bar width.
    final centers = tester
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .map((picture) =>
            tester.getCenter(find.byWidget(picture)).dx)
        .toList()
      ..sort();

    final spacing = screen.width / NavTab.values.length;
    for (var i = 1; i < centers.length; i++) {
      expect(centers[i] - centers[i - 1], closeTo(spacing, 0.01));
    }
  });
}
