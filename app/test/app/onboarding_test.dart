import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/onboarding/onboarding_providers.dart';
import 'package:wanderlock/app/onboarding/onboarding_screen.dart';
import 'package:wanderlock/app/theme.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpWelcome(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('a fresh install has not seen the welcome', () async {
    expect(await container.read(onboardingProvider.future), isFalse);
  });

  test(
    'completing it is remembered by the store, not just in memory',
    () async {
      await container.read(onboardingProvider.future);
      await container.read(onboardingProvider.notifier).complete();

      // A new container over the same database: what a relaunch sees.
      final relaunch = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(relaunch.dispose);
      expect(await relaunch.read(onboardingProvider.future), isTrue);
    },
  );

  testWidgets(
    'three pages, then "later" finishes without asking for location',
    (tester) async {
      await pumpWelcome(tester);
      // Nothing is asked for on arrival: the only way on is a button press.
      expect(find.byKey(const Key('onboarding-later')), findsNothing);

      for (var page = 0; page < OnboardingScreen.pageCount - 1; page++) {
        await tester.tap(find.byKey(const Key('onboarding-primary')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('onboarding-later')));
      await tester.pumpAndSettle();

      expect(container.read(onboardingProvider).value, isTrue);
    },
  );
}
