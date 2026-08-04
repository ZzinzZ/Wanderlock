import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// Builds the app theme entirely from design tokens.
///
/// Nothing here holds a literal design value. Every colour, radius and type
/// style is read from `design/tokens/`, which is what lets dark mode change
/// every surface without a widget being missed.
ThemeData buildAppTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  // Built explicitly rather than with ColorScheme.fromSeed: a generated scheme
  // would introduce colours that are not in the art direction, and Material
  // widgets would quietly pick them up.
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.primaryAction,
    onPrimary: colors.onPrimaryAction,
    secondary: colors.accentYellow,
    onSecondary: colors.onAccentYellow,
    error: colors.coral,
    onError: colors.onCoral,
    surface: colors.card,
    onSurface: colors.ink,
  );

  final textTheme = TextTheme(
    headlineLarge: AppTypography.display,
    titleLarge: AppTypography.screenTitle,
    titleMedium: AppTypography.cardTitle,
    bodyMedium: AppTypography.body,
    labelLarge: AppTypography.button,
    labelMedium: AppTypography.label,
  ).apply(bodyColor: colors.ink, displayColor: colors.ink);

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: AppTypography.uiFamily,
    textTheme: textTheme,
    // Widgets read colours from here, never from AppColors.light/dark.
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.screenTitle.copyWith(color: colors.ink),
    ),
    cardTheme: CardThemeData(
      color: colors.card,
      // Surfaces get their depth from the neumorphic shadow pair in
      // AppShadows, not from Material elevation.
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.card,
      labelStyle: AppTypography.label.copyWith(color: colors.ink),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.primary),
  );
}
