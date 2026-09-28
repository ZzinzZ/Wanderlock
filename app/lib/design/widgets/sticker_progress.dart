import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// A chunky outlined progress bar.
class StickerProgressBar extends StatelessWidget {
  const StickerProgressBar({
    required this.value,
    this.color,
    this.height = AppSpacing.md - 2,
    super.key,
  });

  /// 0 to 1.
  final double value;

  /// Fill. Defaults to [AppColors.progressFill].
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: height + AppSticker.strokeThin * 2,
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: AppMotion.standard,
            curve: AppMotion.linearCurve,
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: color ?? colors.progressFill),
          ),
        ),
      ),
    );
  }
}

/// One pill per step: done, next, or still to go.
///
/// For counts small enough to count at a glance — the five stops of a route,
/// the twelve places of the pilot.
class StickerSegments extends StatelessWidget {
  const StickerSegments({
    required this.total,
    required this.done,
    this.currentIndex,
    this.height = AppSpacing.sm + 2,
    super.key,
  });

  final int total;

  /// Which segments are filled. Indices rather than a count, because the
  /// places reached are not necessarily the first ones.
  final Set<int> done;

  /// Drawn yellow: the one that is next.
  final int? currentIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs - 1),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: done.contains(i)
                    ? colors.progressFill
                    : i == currentIndex
                    ? colors.accentYellow
                    : colors.surfaceMuted,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: colors.outline,
                  width: AppSticker.strokeThin * 0.8,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
