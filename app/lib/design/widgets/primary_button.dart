import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// The canonical primary action: unlock, start a quest, confirm.
///
/// A **solid block**, never a neumorphic surface. Section 5 of the art
/// direction bans soft shadows on primary actions because they dissolve
/// against a map and read as decoration rather than as something to press.
///
/// Pressing shrinks it to [AppMotion.pressedScale]; that is the whole
/// feedback, no ripple, no elevation change.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEnabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? AppMotion.pressedScale : 1,
          duration: AppMotion.quick,
          curve: AppMotion.linearCurve,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isEnabled
                  ? colors.primaryAction
                  : colors.primaryAction.withValues(alpha: 0.4),
              borderRadius: AppRadius.pill,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: AppTypography.button.copyWith(
                  color: colors.onPrimaryAction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
