import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/onboarding/onboarding_art.dart';
import 'package:wanderlock/app/onboarding/onboarding_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/pattern_background.dart';
import 'package:wanderlock/design/widgets/sticker_button.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/checkpoint/application/location_providers.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The welcome: three pages, once, before the first map.
///
/// Follows the design plan (docs/07, C3): no mode to choose — every new player
/// lands in the fog lens — and nothing asked for on arrival. The location
/// permission is requested only from a button the player presses on the last
/// page, never by the screen opening; "later" is always there beside it.
///
/// Says what the product is, not how its controls work: the owner asked for
/// no instructional copy in the interface.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const int pageCount = 3;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _isFinishing = false;

  bool get _isLast => _page == OnboardingScreen.pageCount - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    _pages.nextPage(duration: AppMotion.standard, curve: AppMotion.linearCurve);
  }

  Future<void> _finish({required bool askForLocation}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    if (askForLocation) {
      await ref.read(userLocationProvider.notifier).requestPermission();
    }
    await ref.read(onboardingProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pages = <_Page>[
      _Page(
        title: l10n.onboardingFogTitle,
        body: l10n.onboardingFogBody,
        art: const FogArt(),
      ),
      _Page(
        title: l10n.onboardingUnlockTitle,
        body: l10n.onboardingUnlockBody,
        art: const UnlockArt(),
      ),
      _Page(
        title: l10n.onboardingLensesTitle,
        body: l10n.onboardingLensesBody,
        art: const LensesArt(),
      ),
    ];

    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: AppIconSize.navigation,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _isLast ? 0 : 1,
                      duration: AppMotion.quick,
                      child: IgnorePointer(
                        ignoring: _isLast,
                        child: _SkipChip(
                          label: l10n.onboardingSkip,
                          onPressed: () => _pages.animateToPage(
                            OnboardingScreen.pageCount - 1,
                            duration: AppMotion.standard,
                            curve: AppMotion.linearCurve,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        _PageView(page: pages[i], isCurrent: i == _page),
                    ],
                  ),
                ),
                _Dots(count: pages.length, current: _page),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    key: const Key('onboarding-primary'),
                    isLarge: true,
                    icon: _isLast ? AppIcons.myLocation : null,
                    label: _isLast
                        ? l10n.onboardingStartWithLocation
                        : l10n.onboardingNext,
                    onPressed: _isFinishing
                        ? null
                        : _isLast
                        ? () => _finish(askForLocation: true)
                        : _next,
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.quick,
                  child: _isLast
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: SizedBox(
                            width: double.infinity,
                            child: StickerButton(
                              key: const Key('onboarding-later'),
                              variant: StickerButtonVariant.secondary,
                              label: l10n.onboardingLater,
                              onPressed: _isFinishing
                                  ? null
                                  : () => _finish(askForLocation: false),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page {
  const _Page({required this.title, required this.body, required this.art});

  final String title;
  final String body;
  final Widget art;
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page, required this.isCurrent});

  final _Page page;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            // The art pops in as its page arrives, the way a sticker is
            // slapped on — not a slide, a landing.
            child: AnimatedScale(
              scale: isCurrent ? 1 : 0.8,
              duration: AppMotion.standard,
              curve: AppMotion.standardCurve,
              child: page.art,
            ),
          ),
        ),
        StickerSurface(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg - 4,
            AppSpacing.md + 2,
            AppSpacing.lg - 4,
            AppSpacing.md + 4,
          ),
          child: Column(
            children: [
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTypography.placeTitle.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.quick,
            curve: AppMotion.linearCurve,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == current ? AppSpacing.lg + 4 : AppSpacing.sm + 4,
            height: AppSpacing.sm + 4,
            decoration: BoxDecoration(
              color: i == current ? colors.accentYellow : colors.card,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: colors.outline,
                width: AppSticker.strokeThin,
              ),
            ),
          ),
      ],
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: colors.outline,
              width: AppSticker.strokeThin,
            ),
            boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.xs + 2,
            ),
            child: Text(
              label,
              style: AppTypography.tab.copyWith(color: colors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
