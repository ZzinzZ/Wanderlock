import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/main.dart';

void main() {
  testWidgets('app boots without crashing', (tester) async {
    await tester.pumpWidget(const WanderlockApp());

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
