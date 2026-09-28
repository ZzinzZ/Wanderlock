import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';

/// The title of a full-screen lens, as a yellow ribbon.
///
/// Lives here rather than in either lens because both the album and the
/// journey panel wear one, and a lens may not import another. They were two
/// copies whose comments already pointed at each other.
class LensBanner extends StatelessWidget {
  const LensBanner({required this.icon, required this.title, super.key});

  /// A name from [AppIcons].
  final String icon;

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StickerSurface(
      color: colors.accentYellow,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: AppTypography.banner.copyWith(color: colors.onAccentYellow),
          ),
        ],
      ),
    );
  }
}
