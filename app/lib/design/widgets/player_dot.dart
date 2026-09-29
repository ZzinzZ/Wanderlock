import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// The blue dot that marks where the player is.
///
/// Matches the one MapLibre draws for a real position, so the stand-in
/// explorer and the onboarding illustration cannot drift away from it.
class PlayerDot extends StatelessWidget {
  const PlayerDot({this.hasShadow = true, super.key});

  /// Off where the dot sits on flat artwork rather than over the live map.
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: AppIconSize.inline,
      height: AppIconSize.inline,
      decoration: BoxDecoration(
        color: colors.info,
        shape: BoxShape.circle,
        border: Border.all(color: colors.card, width: AppSticker.strokeHeavy),
        boxShadow: hasShadow
            ? AppShadows.sticker(colors, depth: AppSticker.depthSmall)
            : null,
      ),
    );
  }
}
