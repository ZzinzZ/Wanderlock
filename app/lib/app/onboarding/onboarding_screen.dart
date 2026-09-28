import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/onboarding/onboarding_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
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
        art: const _FogArt(),
      ),
      _Page(
        title: l10n.onboardingUnlockTitle,
        body: l10n.onboardingUnlockBody,
        art: const _UnlockArt(),
      ),
      _Page(
        title: l10n.onboardingLensesTitle,
        body: l10n.onboardingLensesBody,
        art: const _LensesArt(),
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

/// Page one: a patch of city cleared out of the fog around the explorer.
class _FogArt extends StatelessWidget {
  const _FogArt();

  static const double side = 232;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final map = AppMapColors.of(Theme.of(context).brightness);

    return Transform.rotate(
      angle: -AppSticker.tilt * 2,
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.hero,
                  border: Border.all(
                    color: colors.outline,
                    width: AppSticker.strokeHeavy,
                  ),
                  boxShadow: AppShadows.sticker(
                    colors,
                    depth: AppSticker.depthLarge,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.sticker,
                  child: CustomPaint(painter: _FogArtPainter(map: map)),
                ),
              ),
            ),
            Center(
              child: Container(
                width: AppIconSize.inline,
                height: AppIconSize.inline,
                decoration: BoxDecoration(
                  color: colors.info,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.card,
                    width: AppSticker.strokeHeavy,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: -AppSpacing.md,
              top: -AppSpacing.md,
              child: AppIcon(AppIcons.lensJourney, size: AppIconSize.tile),
            ),
          ],
        ),
      ),
    );
  }
}

/// A little cartoon map: paper, a river, two roads, under fog with a soft
/// clearing — the same look as the real fog lens.
class _FogArtPainter extends CustomPainter {
  const _FogArtPainter({required this.map});

  final AppMapColors map;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = map.land);

    final river = Path()
      ..moveTo(w * 0.72, -4)
      ..cubicTo(w * 0.55, h * 0.35, w * 0.95, h * 0.6, w * 0.7, h + 4)
      ..lineTo(w * 0.9, h + 4)
      ..cubicTo(w * 1.1, h * 0.6, w * 0.7, h * 0.35, w * 0.88, -4)
      ..close();
    canvas.drawPath(river, Paint()..color = map.water);

    final casing = Paint()
      ..color = map.roadMajorCasing
      ..strokeWidth = AppSpacing.md - 2
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = map.roadMajor
      ..strokeWidth = AppSpacing.sm + 2
      ..style = PaintingStyle.stroke;
    for (final (from, to) in [
      (Offset(-4, h * 0.3), Offset(w + 4, h * 0.62)),
      (Offset(w * 0.3, -4), Offset(w * 0.42, h + 4)),
    ]) {
      canvas.drawLine(from, to, casing);
      canvas.drawLine(from, to, road);
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = map.fogVeil);
    final clearing = Path()
      ..addOval(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.26))
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.34, h * 0.36), radius: w * 0.16),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.64, h * 0.62), radius: w * 0.15),
      );
    canvas.drawPath(
      clearing,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FogArtPainter oldDelegate) => oldDelegate.map != map;
}

/// Page two: a place still locked, with the radius you have to stand in.
class _UnlockArt extends StatelessWidget {
  const _UnlockArt();

  static const double ring = 236;
  static const double badge = 132;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The radius, drawn as a dashed ring on a tinted disc.
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              color: colors.infoSurface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: PerforationPainter(
                color: colors.info,
                borderRadius: const BorderRadius.all(Radius.circular(ring / 2)),
              ),
            ),
          ),
          Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(
              color: colors.lockedSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.outline,
                width: AppSticker.strokeHeavy,
              ),
              boxShadow: AppShadows.sticker(
                colors,
                depth: AppSticker.depthLarge,
              ),
            ),
            alignment: Alignment.center,
            child: const LandmarkImage(
              LandmarkArt.market,
              size: AppIconSize.celebration,
              isMuted: true,
            ),
          ),
          const Positioned(
            right: AppSpacing.lg,
            top: AppSpacing.md,
            child: AppIcon(AppIcons.locked, size: AppIconSize.tile),
          ),
          const Positioned(
            left: 0,
            bottom: AppSpacing.md,
            child: AppIcon(AppIcons.unlock, size: AppIconSize.tile),
          ),
        ],
      ),
    );
  }
}

/// Page three: the three lenses, fanned like stamps, all lit by one arrival.
class _LensesArt extends StatelessWidget {
  const _LensesArt();

  static const double stamp = 104;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget stampOf(String icon, Color fill, double angle) => Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: stamp,
        height: stamp * 1.2,
        child: StickerSurface(
          color: fill,
          borderRadius: AppRadius.chip,
          depth: AppSticker.depth + 1,
          isPerforated: true,
          padding: EdgeInsets.zero,
          child: Center(child: AppIcon(icon, size: AppIconSize.tile)),
        ),
      ),
    );

    return SizedBox(
      width: stamp * 3,
      height: stamp * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: stamp * 0.45,
            child: stampOf(AppIcons.lensMap, colors.infoSurface, -math.pi / 14),
          ),
          Positioned(
            right: 0,
            top: stamp * 0.45,
            child: stampOf(
              AppIcons.lensJourney,
              colors.decorativeMint,
              math.pi / 14,
            ),
          ),
          Positioned(
            top: stamp * 0.2,
            child: stampOf(AppIcons.lensCollection, colors.highlightSurface, 0),
          ),
          const Positioned(
            top: -AppSpacing.sm,
            right: AppSpacing.xl,
            child: AppIcon(AppIcons.reward, size: AppIconSize.place),
          ),
        ],
      ),
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
