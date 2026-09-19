import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/core/database/database_provider.dart';

/// Whether this install has been through the welcome.
///
/// Lives in `app/` because the welcome is about the whole product — the fog,
/// the unlock, the lenses together — and so belongs to no single feature.
class OnboardingController extends AsyncNotifier<bool> {
  static const String flagKey = 'onboarding_seen';

  @override
  Future<bool> build() async {
    final db = ref.watch(appDatabaseProvider);
    final row = await (db.select(
      db.appFlagRows,
    )..where((flag) => flag.key.equals(flagKey))).getSingleOrNull();
    return row?.value ?? false;
  }

  /// Records that the welcome is done, so it never shows again.
  Future<void> complete() async {
    final db = ref.read(appDatabaseProvider);
    await db
        .into(db.appFlagRows)
        .insertOnConflictUpdate(
          AppFlagRowsCompanion.insert(key: flagKey, value: true),
        );
    state = const AsyncValue.data(true);
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
