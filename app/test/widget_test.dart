import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/screens/home_screen.dart';
import 'package:wanderlock/app/screens/type_specimen_screen.dart';
import 'package:wanderlock/design/widgets/primary_button.dart';
import 'package:wanderlock/main.dart';

void main() {
  testWidgets('app boots and lands on the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WanderlockApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('routes from home to the type specimen and back', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WanderlockApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(TypeSpecimenScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('theme toggle repaints the scaffold in the other theme', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WanderlockApp()));
    await tester.pumpAndSettle();

    Color scaffoldColour() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(Scaffold),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;

    final before = scaffoldColour();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(scaffoldColour(), isNot(before));
  });
}
