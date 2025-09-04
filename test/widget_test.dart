// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endel_clone/main.dart';

void main() {
  testWidgets('Soundscapes app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EndelCloneApp());

    // Verify that our app shows the correct title and modes.
    expect(find.text('Soundscapes'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Relax'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);

    // Verify icons are present
    expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    expect(find.byIcon(Icons.spa), findsOneWidget);
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
  });
}
