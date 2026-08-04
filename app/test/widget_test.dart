import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/screens/home_screen.dart';
import 'package:wanderlock/app/screens/type_specimen_screen.dart';
import 'package:wanderlock/design/widgets/primary_button.dart';
import 'package:wanderlock/main.dart';

/// Delivers the same `popRoute` platform message Android sends when the user
/// presses the system back button or performs the back gesture.
Future<void> _pressSystemBack(WidgetTester tester) {
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
}

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

  // Regression: the in-app back button and the Android system back button are
  // different paths. Navigating with `go` instead of `push` left an empty
  // stack, so system back closed the app rather than returning here. Caught on
  // a device, not by the test above.
  testWidgets('android system back returns to home, it does not exit', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WanderlockApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(TypeSpecimenScreen), findsOneWidget);

    await _pressSystemBack(tester);
    await tester.pumpAndSettle();

    // If the route stack were empty, go_router would have asked the platform
    // to close the app and this screen would never appear.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(TypeSpecimenScreen), findsNothing);
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
