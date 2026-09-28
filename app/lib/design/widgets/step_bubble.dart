import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// A numbered circle: step 3 of a quest, stop 3 of a plan.
///
/// One widget rather than two, because a quest step and an itinerary stop are
/// the same thing to the eye and were the same twelve lines in two features —
/// including the derived font size, which is the part that would have drifted.
class StepBubble extends StatelessWidget {
  const StepBubble({
    required this.ordinal,
    required this.fill,
    required this.ink,
    super.key,
  });

  /// One-based, as the reader counts.
  final int ordinal;

  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: AppIconSize.inline + 6,
      height: AppIconSize.inline + 6,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outline, width: AppSticker.stroke),
      ),
      alignment: Alignment.center,
      child: Text(
        '$ordinal',
        style: AppTypography.badge.copyWith(
          color: ink,
          fontSize: AppTypography.tab.fontSize! + 2,
        ),
      ),
    );
  }
}
