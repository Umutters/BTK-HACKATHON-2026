// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:btk_hackathon_2026/views/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Quick expense sheet opens from main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigation()));

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hızlı Gider Girişi'), findsOneWidget);
  });
}
