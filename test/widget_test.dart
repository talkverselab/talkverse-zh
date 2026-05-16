import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_universe/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ChineseUniverseApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
