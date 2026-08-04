import 'package:flutter/material.dart';

/// Colour tokens, transcribed from docs/09-art-direction.md section 2.
///
/// This file and its siblings in `design/tokens/` are the only places in the
/// app allowed to hold raw colour values; `tool/check_design_tokens.dart`
/// fails the build on literals anywhere else.
///
/// Read them through the theme, never by referencing [light] or [dark]
/// directly, or dark mode will silently miss the widget:
///
/// ```dart
/// final colors = AppColors.of(context);
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.accentYellow,
    required this.onAccentYellow,
    required this.coral,
    required this.onCoral,
    required this.info,
    required this.decorativePurple,
    required this.decorativeMint,
    required this.unlockMoment,
    required this.neumorphicShadow,
    required this.neumorphicHighlight,
  });

  /// Page background.
  final Color background;

  /// Card, sheet and tile surfaces.
  final Color card;

  /// Primary text.
  final Color ink;

  /// Descriptions and labels.
  final Color inkMuted;

  /// Brand green: fills, icons, status. Not legible enough behind white text —
  /// use [primaryAction] for that.
  final Color primary;

  /// Mandatory for any green button carrying white text. The art direction
  /// singles this out because [primary] fails contrast at 2.0:1.
  final Color primaryAction;

  final Color onPrimaryAction;

  /// Secondary call to action.
  final Color accentYellow;

  /// Text on [accentYellow]. The pairing is fixed by the art direction.
  final Color onAccentYellow;

  /// Warnings, and checkpoints that are not yet unlocked.
  final Color coral;

  /// Text on [coral]. Not specified by the art direction, which never pairs
  /// text with coral; dark ink is used in both themes because white on coral
  /// is only 2.6:1. Flagged for sign-off.
  final Color onCoral;

  /// Information and routes.
  final Color info;

  /// Decoration only. Must never carry state meaning.
  final Color decorativePurple;

  /// Decoration only. Must never carry state meaning.
  final Color decorativeMint;

  /// Reserved for the three-second unlock moment and banned everywhere else.
  /// See docs/09-art-direction.md section 9.
  final Color unlockMoment;

  /// Outer shadow for neumorphic surfaces. Never on the map, never on a
  /// primary action: "neumorphism for surfaces, solid blocks for actions".
  final Color neumorphicShadow;

  /// Inner light for neumorphic surfaces.
  final Color neumorphicHighlight;

  static const light = AppColors(
    background: Color(0xFFF7F8FA),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1F2430),
    inkMuted: Color(0xFF6B7280),
    primary: Color(0xFF4CCB8A),
    primaryAction: Color(0xFF17875A),
    onPrimaryAction: Color(0xFFFFFFFF),
    accentYellow: Color(0xFFFFD166),
    onAccentYellow: Color(0xFF5A4210),
    coral: Color(0xFFFF6B6B),
    onCoral: Color(0xFF1F2430),
    info: Color(0xFF4DBDFF),
    decorativePurple: Color(0xFFA26BFF),
    decorativeMint: Color(0xFF7ED6C1),
    unlockMoment: Color(0xFFFF48A0),
    neumorphicShadow: Color(0x141F2430),
    neumorphicHighlight: Color(0xE6FFFFFF),
  );

  /// Dark values come from section 2.2. Where that table is silent the light
  /// value is reused rather than invented — see the notes below.
  static const dark = AppColors(
    background: Color(0xFF14161C),
    card: Color(0xFF1E212A),
    ink: Color(0xFFF2F4F7),
    inkMuted: Color(0xFF9AA3B2),
    primary: Color(0xFF5FD79B),
    // Deliberately identical to light. The dark table does not specify an
    // action green, and an action colour that shifts between themes makes the
    // primary button feel like a different control. Flagged for sign-off.
    primaryAction: Color(0xFF17875A),
    onPrimaryAction: Color(0xFFFFFFFF),
    accentYellow: Color(0xFFFFD87A),
    onAccentYellow: Color(0xFF5A4210),
    coral: Color(0xFFFF8585),
    onCoral: Color(0xFF1F2430),
    info: Color(0xFF6BC9FF),
    decorativePurple: Color(0xFFA26BFF),
    decorativeMint: Color(0xFF7ED6C1),
    unlockMoment: Color(0xFFFF48A0),
    // Neumorphism needs a flat surface and controlled light. On a dark ground
    // the highlight has to be far weaker or the surface looks plastic.
    neumorphicShadow: Color(0x4D000000),
    neumorphicHighlight: Color(0x14FFFFFF),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? ink,
    Color? inkMuted,
    Color? primary,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? accentYellow,
    Color? onAccentYellow,
    Color? coral,
    Color? onCoral,
    Color? info,
    Color? decorativePurple,
    Color? decorativeMint,
    Color? unlockMoment,
    Color? neumorphicShadow,
    Color? neumorphicHighlight,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      primary: primary ?? this.primary,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      accentYellow: accentYellow ?? this.accentYellow,
      onAccentYellow: onAccentYellow ?? this.onAccentYellow,
      coral: coral ?? this.coral,
      onCoral: onCoral ?? this.onCoral,
      info: info ?? this.info,
      decorativePurple: decorativePurple ?? this.decorativePurple,
      decorativeMint: decorativeMint ?? this.decorativeMint,
      unlockMoment: unlockMoment ?? this.unlockMoment,
      neumorphicShadow: neumorphicShadow ?? this.neumorphicShadow,
      neumorphicHighlight: neumorphicHighlight ?? this.neumorphicHighlight,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      onPrimaryAction: Color.lerp(onPrimaryAction, other.onPrimaryAction, t)!,
      accentYellow: Color.lerp(accentYellow, other.accentYellow, t)!,
      onAccentYellow: Color.lerp(onAccentYellow, other.onAccentYellow, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      onCoral: Color.lerp(onCoral, other.onCoral, t)!,
      info: Color.lerp(info, other.info, t)!,
      decorativePurple: Color.lerp(
        decorativePurple,
        other.decorativePurple,
        t,
      )!,
      decorativeMint: Color.lerp(decorativeMint, other.decorativeMint, t)!,
      unlockMoment: Color.lerp(unlockMoment, other.unlockMoment, t)!,
      neumorphicShadow: Color.lerp(
        neumorphicShadow,
        other.neumorphicShadow,
        t,
      )!,
      neumorphicHighlight: Color.lerp(
        neumorphicHighlight,
        other.neumorphicHighlight,
        t,
      )!,
    );
  }
}
