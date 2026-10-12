// Basic widget tests for the app's navbar shell.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gathermap/main.dart';
import 'package:gathermap/views/widgets/navbar.dart';

void main() {
  testWidgets('App renders navbar with four tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(Navbar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(4));

    // Default tab (initialIndex: 1) shows page 2.
    expect(find.text('You have pressed the button 0 times on page 2 or 4.'),
        findsOneWidget);
  });

  testWidgets('Tapping the FAB increments the page counter',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('You have pressed the button 1 times on page 2 or 4.'),
        findsOneWidget);
  });

  testWidgets('Switching tabs shows the corresponding page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.text('You have pressed the button 0 times in page 1 or 3.'),
        findsOneWidget);
  });
}
