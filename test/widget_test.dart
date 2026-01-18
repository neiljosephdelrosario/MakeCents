import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makecents_capstone/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Make Cents'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
