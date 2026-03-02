// test/widget_test.dart
// Flutter generates this file automatically but it references
// the old MyApp widget. We replace it with a basic smoke test
// that just confirms the app boots without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railfocus/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    // Build the app and trigger one frame
    await tester.pumpWidget(const RailFocusApp());
    // Verify the app renders something
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}