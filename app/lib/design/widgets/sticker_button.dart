import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';

/// How loud a [StickerButton] is.
enum StickerButtonVariant {
  /// Yellow. The one action the screen exists for — at most one per screen.
  primary,

  /// Card-coloured. Everything else.
  secondary,
}

/// A pill-shaped sticker that presses into the page.
///
/// Pressing drops it onto its own shadow — the shadow shrinks to nothing and
/// the button moves down by the same amount — which is the whole feedback:
/// no ripple, no colour change. It is what a sticker would do if you pushed
/// it.
class StickerButton extends StatefulWidget {
  const StickerButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = StickerButtonVariant.primary,
    this.isLarge = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// One of the [AppIcons] constants, drawn before the label.
  final String? icon;
  final StickerButtonVariant variant;

  /// The hero size, for the one action a screen is about.
  final bool isLarge;

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEnabled = widget.onPressed != null;
    final depth = widget.isLarge ? AppSticker.depthLarge : AppSticker.depth;
    final drop = _isPressed ? depth : 0.0;

    final fill = switch (widget.variant) {
      StickerButtonVariant.primary => colors.accentYellow,
      StickerButtonVariant.secondary => colors.card,
    };
    final ink = switch (widget.variant) {
      StickerButtonVariant.primary => colors.onAccentYellow,
      StickerButtonVariant.secondary => colors.ink,
    };
    final labelStyle = widget.isLarge
        ? AppTypography.stickerButton
        : AppTypography.hudTitle;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: Padding(
            // Reserve the shadow's room so pressing never moves the layout.
            padding: EdgeInsets.only(bottom: depth),
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.linearCurve,
              transform: Matrix4.translationValues(0, drop, 0),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: widget.isLarge ? AppSpacing.md : AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: colors.outline,
                  width: widget.isLarge
                      ? AppSticker.strokeHeavy
                      : AppSticker.stroke,
                ),
                boxShadow: AppShadows.sticker(colors, depth: depth - drop),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    AppIcon(
                      widget.icon!,
                      size: widget.isLarge
                          ? AppIconSize.navigation
                          : AppIconSize.inline + AppSpacing.xs,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle.copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
