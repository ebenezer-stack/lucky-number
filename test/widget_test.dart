import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucky_numbers/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LuckyNumbersApp());
    expect(find.text('Lucky Numbers'), findsOneWidget);
  });
}
