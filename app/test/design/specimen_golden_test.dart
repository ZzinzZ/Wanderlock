@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/screens/type_specimen_screen.dart';
import 'package:wanderlock/app/theme.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Renders the type specimen to PNG so Vietnamese diacritics can be inspected
/// without a device.
///
/// Tagged `golden` and excluded from CI on purpose: text rasterisation differs
/// between Windows and the Linux runner, so a byte-comparison across platforms
/// would fail for reasons that have nothing to do with the fonts. These images
/// are a local review artifact. The device screenshot in the F1 Definition of
/// Done is still the real check — this one catches "the font did not load at
/// all", which is the failure that actually happens.
///
/// Regenerate:
///   flutter test --update-goldens test/design/specimen_golden_test.dart
void main() {
  setUpAll(() async {
    await _loadBundledFont('BeVietnamPro', [
      'assets/fonts/BeVietnamPro-Regular.ttf',
      'assets/fonts/BeVietnamPro-Medium.ttf',
      'assets/fonts/BeVietnamPro-SemiBold.ttf',
      'assets/fonts/BeVietnamPro-Bold.ttf',
    ]);
    await _loadBundledFont('Baloo2', ['assets/fonts/Baloo2-Variable.ttf']);
  });

  for (final brightness in Brightness.values) {
    testWidgets('type specimen renders in ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TypeSpecimenScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TypeSpecimenScreen),
        matchesGoldenFile('goldens/type_specimen_${brightness.name}.png'),
      );
    });
  }
}

/// Loads a bundled font from disk rather than through `rootBundle`, so the
/// test does not depend on how the asset bundle is assembled for tests.
Future<void> _loadBundledFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
