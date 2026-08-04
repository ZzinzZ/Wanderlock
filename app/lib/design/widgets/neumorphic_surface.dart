import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// A raised or debossed surface: sheets, cards, icon tiles, stamps.
///
/// The other half of the rule that [PrimaryButton] embodies — *neumorphism for
/// surfaces, solid blocks for actions*.
///
/// Only use this on a flat, single-colour ground. Never over the map: the soft
/// shadow pair needs controlled light and dissolves against a multicoloured
/// background. For map overlays use [AppShadows.overMap] instead.
class NeumorphicSurface extends StatelessWidget {
  const NeumorphicSurface({
    required this.child,
    this.borderRadius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.isInset = false,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Pressed into the page rather than raised out of it. Used for the
  /// stamp-in-paper effect on the collection screen.
  final bool isInset;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: borderRadius,
        boxShadow: isInset
            ? AppShadows.inset(colors)
            : AppShadows.raised(colors),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
