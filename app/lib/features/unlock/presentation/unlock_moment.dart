import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/unlock/presentation/unlock_painters.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The three seconds a checkpoint opens.
///
/// Section 9 of the art direction gives this six beats, laid out below on one
/// controller in the order the document lists them, so the sequence reads
/// against the spec.
///
/// Takes a name and a photograph rather than a checkpoint: `unlock` is the
/// foundation every lens depends on and may not depend on one in return.
///
/// **Pink lives here and nowhere else**, and a test asserts it.
class UnlockMoment extends StatefulWidget {
  const UnlockMoment({
    required this.placeName,
    required this.onCompleted,
    this.photoUrl,
    this.landmark,
    this.origin = Alignment.center,
    super.key,
  });

  final String placeName;

  /// Where the colour floods from — the user's position on the map, in
  /// alignment coordinates. Centre when the map cannot say where they are.
  final Alignment origin;

  final String? photoUrl;

  /// A `LandmarkArt` name, drawn on the plate while there is no photograph.
  /// A name rather than a checkpoint, for the same reason as [placeName].
  final String? landmark;

  /// Called once, after the last beat.
  final VoidCallback onCompleted;

  @override
  State<UnlockMoment> createState() => _UnlockMomentState();
}

class _UnlockMomentState extends State<UnlockMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Beat 1 — colour floods out from the user.
  late final Animation<double> _flood;

  /// Beat 2 — the photograph comes back into colour.
  late final Animation<double> _saturation;

  /// Beat 3 — the name arrives.
  late final Animation<double> _name;

  /// Beat 4 — the badge drops into the collection.
  late final Animation<double> _badge;

  /// The whole thing fading out, so it does not cut.
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.unlockMoment,
      vsync: this,
    );

    // Fractions of the three seconds, on one controller rather than four, so
    // the beats stay in proportion if the duration is ever retuned.
    _flood = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: AppMotion.linearCurve),
    );
    _saturation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.55, curve: AppMotion.linearCurve),
    );
    _name = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.6, curve: AppMotion.standardCurve),
    );
    _badge = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: AppMotion.standardCurve),
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1, curve: AppMotion.linearCurve),
    );

    // Beat 6 — haptic, twice: once with the flood, once with the badge, so
    // the moment has a shape in the hand as well as on screen.
    //
    // The short sound the art direction also asks for is not here: there is no
    // audio package in this build, and a silent stub would read as done.
    HapticFeedback.mediumImpact();
    _badge.addStatusListener(_onBadgeStatus);

    _controller.forward().whenComplete(() {
      if (mounted) widget.onCompleted();
    });
  }

  void _onBadgeStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _badge.removeStatusListener(_onBadgeStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 1 - _exit.value,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Beat 1.
              CustomPaint(
                painter: FloodPainter(
                  progress: _flood.value,
                  origin: widget.origin,
                  colour: colors.unlockMoment,
                ),
              ),
              // The spinning sunburst of the sticker pass. It rides on the
              // flood rather than on its own beat: it is the flood's texture.
              CustomPaint(
                painter: RayPainter(
                  turn: _controller.value,
                  opacity: _flood.value,
                  colour: colors.unlockRay,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Beat 3, heading first: the headline lands with the
                      // name so the screen reads top to bottom.
                      Opacity(
                        opacity: _name.value.clamp(0, 1),
                        child: _OutlinedHeading(text: l10n.unlockMomentHero),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Beat 2.
                      Transform.scale(
                        scale: 0.6 + 0.4 * _flood.value,
                        child: _Plate(
                          photoUrl: widget.photoUrl,
                          landmark: widget.landmark,
                          placeName: widget.placeName,
                          colourReturn: _saturation.value,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Beat 4.
                      _BadgeDrop(
                        progress: _badge.value,
                        lines: [
                          (AppIcons.revealed, l10n.unlockRewardFog),
                          (AppIcons.lensCollection, l10n.unlockRewardStamp),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The headline, in cream with a thick ink outline and a hard shadow — the
/// sticker look applied to type.
///
/// The fill is cream, not the theme's ink, and that is only legible because
/// of the outline: cream on this pink alone measures about 3:1. The outline
/// is what carries the contrast, which is why it is drawn at a heavy stroke.
class _OutlinedHeading extends StatelessWidget {
  const _OutlinedHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = AppTypography.hero;

    // The outline, drawn twice: once dropped by the sticker depth as the
    // shadow, once in place. Written once so the two cannot drift apart.
    final outlined = Text(
      text,
      textAlign: TextAlign.center,
      style: style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSticker.strokeHeavy * 2
          ..strokeJoin = StrokeJoin.round
          ..color = colors.outline,
      ),
    );

    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, AppSticker.depth + 1),
          child: outlined,
        ),
        outlined,
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: colors.card),
        ),
      ],
    );
  }
}

/// Beat 2 — the place, as the stamp being handed over, arriving in colour.
///
/// A licensed photograph when one exists; until then the building sticker,
/// which is the same art the map and the album show, so the stamp is
/// recognisably the one that is about to appear in the collection.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.photoUrl,
    required this.landmark,
    required this.placeName,
    required this.colourReturn,
  });

  final String? photoUrl;
  final String? landmark;
  final String placeName;
  final double colourReturn;

  static const double width = 232;
  static const double artSide = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final Widget art;
    if (photoUrl != null) {
      art = ClipRRect(
        borderRadius: AppRadius.chip,
        child: Image.network(
          photoUrl!,
          width: artSide,
          height: artSide,
          fit: BoxFit.cover,
        ),
      );
    } else if (landmark != null) {
      art = LandmarkImage(landmark!, size: artSide);
    } else {
      art = SizedBox(
        width: artSide,
        height: artSide,
        child: Center(
          child: Text(
            l10n.checkpointPhotoPending,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(color: colors.inkMuted),
          ),
        ),
      );
    }

    return Transform.rotate(
      angle: AppSticker.heroTilt,
      child: SizedBox(
        width: width,
        child: StickerSurface(
          // Yellow, and the same in both themes: the flood does not change
          // with the theme, so nor does the object floating on it.
          color: colors.accentYellow,
          borderRadius: AppRadius.hero,
          depth: AppSticker.depthHero,
          stroke: AppSticker.strokeHeavy,
          isPerforated: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md + 2,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grey at the start, full colour by the end of the beat: "colour
              // returns to where you have been", applied to the place itself.
              ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _saturationMatrix(colourReturn),
                ),
                child: art,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                placeName,
                textAlign: TextAlign.center,
                style: AppTypography.placeTitle.copyWith(
                  // Theme-independent ink on a theme-independent plate.
                  color: colors.onAccentYellow,
                  fontSize: AppTypography.banner.fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A saturation matrix, where 0 is fully grey and 1 leaves colour untouched.
  static List<double> _saturationMatrix(double saturation) {
    // Luminance weights for sRGB. Using a flat third each would grey the image
    // in a way that reads as washed out rather than as black and white.
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    final s = saturation.clamp(0.0, 1.0);
    final inverse = 1 - s;

    return <double>[
      inverse * r + s, inverse * g, inverse * b, 0, 0, //
      inverse * r, inverse * g + s, inverse * b, 0, 0, //
      inverse * r, inverse * g, inverse * b + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// Beat 4 — what the arrival just changed, dropping in as one sticker.
///
/// Says in words what the architecture does silently: one arrival, and every
/// lens has already moved.
class _BadgeDrop extends StatelessWidget {
  const _BadgeDrop({required this.progress, required this.lines});

  final double progress;
  final List<(String, String)> lines;

  /// How far above its resting place the card starts.
  static const double dropHeight = 64;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settled = progress.clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, dropHeight * (1 - settled)),
      child: Opacity(
        opacity: settled,
        child: StickerSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.sm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (icon, text) in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs / 2,
                  ),
                  child: Row(
                    children: [
                      AppIcon(icon, size: AppIconSize.inline + 6),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          text,
                          style: AppTypography.tab.copyWith(color: colors.ink),
                        ),
                      ),
                      const AppIcon(AppIcons.visited, size: AppIconSize.inline),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
