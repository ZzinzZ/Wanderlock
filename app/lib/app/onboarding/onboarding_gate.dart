import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/onboarding/onboarding_providers.dart';
import 'package:wanderlock/app/onboarding/onboarding_screen.dart';
import 'package:wanderlock/app/screens/explore_screen.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/pattern_background.dart';

/// The first route: the welcome on a first launch, the map on every other.
///
/// A gate widget rather than a router redirect, because the answer comes from
/// the database and a redirect cannot wait for it. While it loads the screen
/// shows the welcome's own backing sheet, so neither screen flashes on the way
/// to the other.
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingProvider);

    final Widget child = switch (seen) {
      AsyncData(value: true) => const ExploreScreen(),
      AsyncData(value: false) => const OnboardingScreen(),
      // A store that cannot be read must not lock the player out of the map.
      AsyncError() => const ExploreScreen(),
      _ => const PatternBackground(child: SizedBox.expand()),
    };

    return AnimatedSwitcher(duration: AppMotion.standard, child: child);
  }
}
