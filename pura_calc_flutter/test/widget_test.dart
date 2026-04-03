import 'package:flutter_test/flutter_test.dart';

import 'package:pura_calc_flutter/main.dart';

void main() {
  testWidgets('Calculator app renders main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
