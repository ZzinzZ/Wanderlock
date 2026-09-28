import 'package:flutter/material.dart';

import 'package:wanderlock/design/widgets/sticker_button.dart';

/// The canonical primary action: unlock, start a quest, confirm.
///
/// Since the sticker pass (docs/09-art-direction.md, section 0) this is the
/// yellow [StickerButton] under its old name, kept so the call sites read as
/// intent — "the primary action" — rather than as a colour.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLarge = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// One of the `AppIcons` constants.
  final String? icon;
  final bool isLarge;

  @override
  Widget build(BuildContext context) => StickerButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLarge: isLarge,
  );
}
