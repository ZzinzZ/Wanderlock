import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wanderlock/app/routes.dart';
import 'package:wanderlock/app/theme_mode_controller.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/neumorphic_surface.dart';
import 'package:wanderlock/design/widgets/primary_button.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Placeholder home screen for phase F1.
///
/// Exists to prove the shell works: tokens, both themes, routing and
/// localisation. The real home screen is the full-screen map, built in F3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(brightness),
            child: Text(isDark ? l10n.switchToLight : l10n.switchToDark),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle, style: AppTypography.display),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.homeSubtitle,
                style: AppTypography.body.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              NeumorphicSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.diacriticsSample, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.diacriticsSentence,
                      style: AppTypography.body.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.openTypeSpecimen,
                // push, not go: `go` replaces the location, which leaves
                // nothing on the stack for the Android back button to pop.
                // Pressing back would exit the app instead of coming here.
                onPressed: () => context.push(AppRoutes.typeSpecimen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
