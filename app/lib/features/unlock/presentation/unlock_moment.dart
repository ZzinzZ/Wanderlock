import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The three seconds a checkpoint opens.
///
/// Section 9 of the art direction gives this six beats and says it is the one
/// place in the product allowed to go all out. They are laid out on a single
/// controller below, in the order the document lists them, so the sequence can
/// be read against the spec rather than reverse-engineered from six widgets.
///
/// It takes a name and a photograph rather than a checkpoint: `unlock` is the
/// foundation every lens depends on and may not depend on a feature in return.
///
/// **Pink lives here and nowhere else.** [AppColors.unlockMoment] is banned
/// everywhere else by the art direction, and a test asserts that this file is
/// its only reader.
class UnlockMoment extends StatefulWidget {
  const UnlockMoment({
    required this.placeName,
    required this.onCompleted,
    this.photoUrl,
    this.origin = Alignment.center,
    super.key,
  });

  final String placeName;

  /// Where the colour floods from — the user's position on the map, in
  /// alignment coordinates. Centre when the map cannot say where they are.
  final Alignment origin;

  final String? photoUrl;

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

    // Intervals are fractions of the three seconds: 0.00–0.35 is the flood,
    // and so on. Written as a chain rather than as four controllers because
    // the beats have to stay in proportion if the duration is ever retuned.
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

    // Beat 6 — haptic. Two taps rather than one: the first lands with the
    // flood, the second with the badge, which is what makes the moment feel
    // like it has a shape in the hand as well as on screen.
    //
    // The short sound the art direction also asks for is not here. There is no
    // audio asset and no audio package in this build, and a silent stub would
    // read as done.
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
                painter: _FloodPainter(
                  progress: _flood.value,
                  origin: widget.origin,
                  colour: colors.unlockMoment,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Beat 2.
                    _PhotoPlate(
                      photoUrl: widget.photoUrl,
                      colourReturn: _saturation.value,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Beat 3.
                    Opacity(
                      opacity: _name.value.clamp(0, 1),
                      child: Column(
                        children: [
                          Text(
                            l10n.unlockMomentHeading,
                            style: AppTypography.label.copyWith(
                              color: colors.onUnlockMoment,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.placeName,
                            textAlign: TextAlign.center,
                            // Not the theme's ink: the flood is the same pink
                            // in both themes, so the name on it must be too,
                            // or dark mode would put near-white on pink at
                            // 3.09:1.
                            style: AppTypography.display.copyWith(
                              color: colors.onUnlockMoment,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Beat 4.
                    _BadgeDrop(progress: _badge.value),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Beat 1 — a disc of colour opening from where the user is standing.
class _FloodPainter extends CustomPainter {
  const _FloodPainter({
    required this.progress,
    required this.origin,
    required this.colour,
  });

  final double progress;
  final Alignment origin;
  final Color colour;

  /// How solid the flood gets. Full opacity would hide the map it is
  /// celebrating.
  static const double peakOpacity = 0.92;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final centre = origin.alongSize(size);
    // Far corner, so the disc always finishes off-screen rather than stopping
    // as a visible circle.
    final reach = math.sqrt(
      size.width * size.width + size.height * size.height,
    );

    canvas.drawCircle(
      centre,
      reach * progress,
      Paint()..color = colour.withValues(alpha: peakOpacity * progress),
    );
  }

  @override
  bool shouldRepaint(_FloodPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.origin != origin ||
      oldDelegate.colour != colour;
}

/// Beat 2 — the landmark, arriving in colour.
///
/// With no photograph yet, what returns to colour is the plate itself. The
/// beat is real either way, and the day a licensed photograph exists it drops
/// into the same box behind the same animation.
class _PhotoPlate extends StatelessWidget {
  const _PhotoPlate({required this.photoUrl, required this.colourReturn});

  final String? photoUrl;
  final double colourReturn;

  static const double side = 180;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final plate = SizedBox(
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: colors.card,
        ),
        child: photoUrl == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.checkpointPhotoPending,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(color: colors.inkMuted),
                  ),
                ),
              )
            : Image.network(photoUrl!, fit: BoxFit.cover),
      ),
    );

    // Grey at the start, full colour by the end of the beat: the art
    // direction's "colour returns to where you have been", applied to the
    // landmark rather than to the map.
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturationMatrix(colourReturn)),
        child: plate,
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

/// Beat 4 — the badge falling into the collection.
class _BadgeDrop extends StatelessWidget {
  const _BadgeDrop({required this.progress});

  final double progress;

  static const double side = 64;

  /// How far above its resting place the badge starts.
  static const double dropHeight = 48;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settled = progress.clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, dropHeight * (1 - settled)),
      child: Opacity(
        opacity: settled,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: AppRadius.marker,
            color: colors.card,
          ),
          child: Icon(Icons.local_activity, color: colors.unlockMoment),
        ),
      ),
    );
  }
}
