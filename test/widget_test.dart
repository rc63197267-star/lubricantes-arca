import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ml/main.dart';

void main() {
  testWidgets('app loads dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LubricantesArcaApp());

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Lubricantes Arca'), findsWidgets);
  });
}
