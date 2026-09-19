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
    required this.surfaceMuted,
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
    required this.onUnlockMoment,
    required this.neumorphicShadow,
    required this.neumorphicHighlight,
    required this.outline,
    required this.patternGround,
    required this.patternDot,
    required this.lockedSurface,
    required this.infoSurface,
    required this.highlightSurface,
    required this.progressFill,
    required this.unlockRay,
  });

  /// Page background.
  final Color background;

  /// Card, sheet and tile surfaces.
  final Color card;

  /// A surface one step quieter than [card].
  ///
  /// Introduced when the owner asked for the green fills to go and for the
  /// icons to carry the colour instead. That left every surface neutral, and
  /// two neutral surfaces sitting on each other — a selected chip on its bar,
  /// an unearned stamp among earned ones — need to be told apart by something.
  /// This is that something: near-white in light, a shade above the card in
  /// dark.
  ///
  /// It is deliberately a weak difference. Anything stronger competes with the
  /// icons, which are now the only thing on screen allowed to be loud.
  final Color surfaceMuted;

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

  /// Text on [coral]. The art direction never pairs text with coral, so this
  /// was chosen rather than transcribed: dark ink in both themes, because
  /// white on coral is only 2.6:1. Signed off 2026-08-05.
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

  /// Text drawn on top of [unlockMoment].
  ///
  /// Dark ink in **both** themes, and chosen rather than transcribed: the
  /// flood is the same pink whatever the theme, so its text cannot follow the
  /// theme. White on `#FF48A0` measures 3.09:1 and fails the art direction's
  /// own 4.5:1 rule for normal text; this ink measures 5.07:1.
  ///
  /// Found by looking at the first build, where the heading was drawn in the
  /// pink itself and was simply invisible against the pink behind it.
  final Color onUnlockMoment;

  /// Outer shadow for neumorphic surfaces. Never on the map, never on a
  /// primary action: "neumorphism for surfaces, solid blocks for actions".
  final Color neumorphicShadow;

  /// Inner light for neumorphic surfaces.
  final Color neumorphicHighlight;

  /// The ink line drawn round every sticker, and the hard shadow under it.
  ///
  /// The sticker look (docs/09-art-direction.md, section 0) is carried by
  /// this one colour more than by any fill: an outline plus a solid offset
  /// shadow is what makes a flat card read as something stuck onto the
  /// screen rather than printed on it.
  final Color outline;

  /// Ground of the polka-dot backdrop behind full-screen lenses.
  final Color patternGround;

  /// The dots on [patternGround]. Deliberately a small step from it: the
  /// pattern is texture, and must never compete with the stickers on it.
  final Color patternDot;

  /// Fill of a place, stamp or step not yet reached. Warm grey rather than
  /// the card, so a locked sticker reads as unpainted rather than blank.
  final Color lockedSurface;

  /// Fill for route and quest banners. Light enough to carry ink text.
  final Color infoSurface;

  /// Fill for the one thing on screen that is next: the target place, the
  /// next quest step.
  final Color highlightSurface;

  /// Progress bars and reached segments. Never carries text.
  final Color progressFill;

  /// The lighter rays spinning behind the unlock flood. Pink family, so it
  /// is bound by the same rule as [unlockMoment]: the three seconds only.
  final Color unlockRay;

  /// The sticker palette, settled 2026-09-19 — docs/09-art-direction.md,
  /// section 0. Warm cream ground, plum ink, saturated fills. The values it
  /// replaced (the neutral-surface palette of 2026-08-25) are in git history.
  static const light = AppColors(
    background: Color(0xFFFFF4DE),
    card: Color(0xFFFFFDF7),
    surfaceMuted: Color(0xFFF1E7CF),
    ink: Color(0xFF2B2140),
    inkMuted: Color(0xFF5A4E6B),
    primary: Color(0xFF7ED957),
    primaryAction: Color(0xFF17875A),
    onPrimaryAction: Color(0xFFFFFFFF),
    accentYellow: Color(0xFFFFC93C),
    // Ink, not the old brown: every sticker button is outlined in ink, and a
    // second dark tone on the same button reads as a mistake.
    onAccentYellow: Color(0xFF2B2140),
    coral: Color(0xFFFF6B5B),
    onCoral: Color(0xFF2B2140),
    info: Color(0xFF2F9BEA),
    decorativePurple: Color(0xFFA26BFF),
    decorativeMint: Color(0xFFC9F0D6),
    unlockMoment: Color(0xFFFF48A0),
    onUnlockMoment: Color(0xFF2B2140),
    neumorphicShadow: Color(0x142B2140),
    neumorphicHighlight: Color(0xE6FFFFFF),
    outline: Color(0xFF2B2140),
    patternGround: Color(0xFFC9F0D6),
    patternDot: Color(0xFFA3DFB9),
    lockedSurface: Color(0xFFE6DFD0),
    infoSurface: Color(0xFFBFE4FF),
    highlightSurface: Color(0xFFFFF3CC),
    progressFill: Color(0xFF7ED957),
    unlockRay: Color(0xFFFF6BB4),
  );

  /// Night version of the same stickers: plum ground, cream ink.
  ///
  /// The outline is **lighter** than the card here, not darker. The first
  /// draft used near-black, and the contrast test measured it at 1.33:1
  /// against the card — the outline, which is the whole sticker look, had
  /// vanished. Same lesson as the dark map's road casing: on a ground that is
  /// already close to black, an edge has to go the other way to be seen.
  static const dark = AppColors(
    background: Color(0xFF1C1829),
    card: Color(0xFF2A2440),
    surfaceMuted: Color(0xFF342D4D),
    ink: Color(0xFFFFF8E7),
    inkMuted: Color(0xFFB9AFCB),
    primary: Color(0xFF7ED957),
    // Deliberately identical to light: an action colour that shifts between
    // themes makes the button feel like a different control.
    primaryAction: Color(0xFF17875A),
    onPrimaryAction: Color(0xFFFFFFFF),
    accentYellow: Color(0xFFFFC93C),
    onAccentYellow: Color(0xFF2B2140),
    coral: Color(0xFFFF8575),
    onCoral: Color(0xFF2B2140),
    info: Color(0xFF6BC9FF),
    decorativePurple: Color(0xFFA26BFF),
    decorativeMint: Color(0xFF2E4A3F),
    unlockMoment: Color(0xFFFF48A0),
    // Same ink as light: the flood does not change between themes, so nor
    // may the text on it.
    onUnlockMoment: Color(0xFF2B2140),
    neumorphicShadow: Color(0x4D000000),
    neumorphicHighlight: Color(0x14FFFFFF),
    outline: Color(0xFF8C80B8),
    patternGround: Color(0xFF231E33),
    patternDot: Color(0xFF2F2844),
    lockedSurface: Color(0xFF3A3450),
    infoSurface: Color(0xFF24476A),
    highlightSurface: Color(0xFF4A3F22),
    progressFill: Color(0xFF7ED957),
    unlockRay: Color(0xFFFF6BB4),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? surfaceMuted,
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
    Color? onUnlockMoment,
    Color? neumorphicShadow,
    Color? neumorphicHighlight,
    Color? outline,
    Color? patternGround,
    Color? patternDot,
    Color? lockedSurface,
    Color? infoSurface,
    Color? highlightSurface,
    Color? progressFill,
    Color? unlockRay,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
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
      onUnlockMoment: onUnlockMoment ?? this.onUnlockMoment,
      neumorphicShadow: neumorphicShadow ?? this.neumorphicShadow,
      neumorphicHighlight: neumorphicHighlight ?? this.neumorphicHighlight,
      outline: outline ?? this.outline,
      patternGround: patternGround ?? this.patternGround,
      patternDot: patternDot ?? this.patternDot,
      lockedSurface: lockedSurface ?? this.lockedSurface,
      infoSurface: infoSurface ?? this.infoSurface,
      highlightSurface: highlightSurface ?? this.highlightSurface,
      progressFill: progressFill ?? this.progressFill,
      unlockRay: unlockRay ?? this.unlockRay,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
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
      onUnlockMoment: Color.lerp(onUnlockMoment, other.onUnlockMoment, t)!,
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
      outline: Color.lerp(outline, other.outline, t)!,
      patternGround: Color.lerp(patternGround, other.patternGround, t)!,
      patternDot: Color.lerp(patternDot, other.patternDot, t)!,
      lockedSurface: Color.lerp(lockedSurface, other.lockedSurface, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      highlightSurface: Color.lerp(
        highlightSurface,
        other.highlightSurface,
        t,
      )!,
      progressFill: Color.lerp(progressFill, other.progressFill, t)!,
      unlockRay: Color.lerp(unlockRay, other.unlockRay, t)!,
    );
  }
}
