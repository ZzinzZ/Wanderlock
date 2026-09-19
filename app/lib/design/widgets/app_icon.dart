import 'package:flutter/widgets.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// A 3D icon, drawn in its own colours.
///
/// The art direction bans icons taken from a generic line set and asks for the
/// dimensional look of section 7.2. The source is 3dicons.co, CC0. See
/// `content/icon-licenses.md`.
///
/// **The `color` variant, used as it comes.** An earlier pass took the `clay`
/// variant and tinted it to the palette; the owner chose the full-colour
/// artwork instead, on the grounds that the product is aimed at younger users
/// and should look it. Two consequences worth stating rather than discovering:
///
/// 1. Tinting is gone. Clay is monochrome and takes a tint; these already
///    carry their own hues, and multiplying a tint over them would muddy every
///    one of them.
/// 2. Each icon brings its own colours to a screen. Section 2.3 of the art
///    direction caps a screen at three accent colours, and that rule — not the
///    gradient ban — is the one this decision actually spends. Icons are
///    therefore chosen per screen with an eye on how many hues land at once.
///
/// Sizes still come from [AppIconSize], because a size is a design value like
/// any other.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    this.size = AppIconSize.action,
    this.semanticLabel,
    this.isMuted = false,
    super.key,
  });

  /// One of the [AppIcons] constants.
  final String name;

  final double size;

  /// Drains the colour out of the icon.
  ///
  /// The surfaces are neutral now, so colour is the only signal left for state
  /// — and section 8 of the art direction already says what colour means here:
  /// "colour returns to where you have been". A place not yet reached, a lens
  /// not currently selected, a camera not currently following: grey. Reaching
  /// it turns the colour on.
  final bool isMuted;

  /// Left null for an icon that only repeats what the text beside it says.
  /// Screen readers should not read a label twice.
  final String? semanticLabel;

  static String assetPath(String name) => 'assets/icons/$name.png';

  /// Fully desaturating colour matrix.
  ///
  /// sRGB luminance weights rather than a flat third each: an even split greys
  /// a red padlock and a green medal to nearly the same value, and the icons
  /// stop being distinguishable at a glance.
  static const List<double> greyscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath(name),
      width: size,
      height: size,
      semanticLabel: semanticLabel,
    );

    if (!isMuted) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(greyscaleMatrix),
      child: image,
    );
  }
}

/// The icons bundled with the app.
///
/// Names match the file in `assets/icons/` and the slug in
/// `content/icons/3dicons-manifest.json`, so an icon can be traced back to the
/// exact source file it came from.
///
/// Both full 120-icon sets are kept in `content/icons/` — `3dicons-color/` is
/// what ships, `3dicons-clay/` is retained because it is what a future tinted
/// surface would need and re-downloading it is not free. Only
/// what a screen actually uses is bundled, because everything in `assets/`
/// ships inside the binary whether it is drawn or not.
class AppIcons {
  const AppIcons._();

  // Lens switcher — the three entries of section 5.4.
  static const String lensMap = 'map-pin';
  static const String lensCollection = 'medal';
  static const String lensJourney = 'explorer';

  // Checkpoint state, section 5.3.
  static const String locked = 'lock';
  static const String visited = 'tick';
  static const String revealed = 'pin';

  // Actions on a checkpoint.
  static const String unlock = 'key';
  static const String addToItinerary = 'plus';

  /// Removing a place from a plan. Deletion rather than dismissal, which is
  /// why this is a bin and not a cross.
  static const String removeFromItinerary = 'trash-can';
  static const String story = 'notebook';
  static const String questStep = 'target';

  // Map controls.
  static const String myLocation = 'location';

  // Story player.
  static const String play = 'play';
  static const String pause = 'pause';
  static const String next = 'next';
  static const String back = 'back';

  // Quest and reward.
  static const String questRoute = 'flag';
  static const String trophy = 'trophy';

  /// The badge that drops during the unlock moment. A star rather than the
  /// medal used for a stamp: the moment is the reward, the album entry is the
  /// record of it, and giving them the same icon made the three seconds look
  /// like a preview of the grid.
  static const String reward = 'star';

  // Memory map.
  static const String camera = 'camera';
  static const String picture = 'picture';

  // Settings and theme.
  static const String settings = 'setting';
  static const String themeLight = 'sun';
  static const String themeDark = 'moon';

  // Places on the map. Section 5.4 asks the map to read before its labels do,
  // so these are chosen for what a place *is*, not for what class it belongs
  // to. See CheckpointIcons for which place gets which.
  static const String placePostOffice = 'mail';
  static const String placeTower = 'rocket';
  static const String placeWharf = 'travel';
  static const String placePalace = 'flag';
  static const String placeMuseum = 'picture';
  static const String placeMarket = 'bag';
  static const String placeTomb = 'crown';
  static const String placeTemple = 'fire';

  // Edge states, section 5.6.
  static const String offline = 'wifi';
  static const String quiz = 'puzzle';
  static const String warning = 'sheild';

  /// Every constant above, in order, aliases included.
  ///
  /// Two names may point at one file on purpose: a flag is both a quest route
  /// and the palace that flies one, and a picture is both the memory map and
  /// the museum full of them. The constants are named for what they mean, not
  /// for what they draw, so the list keeps both and [all] collapses them.
  static const List<String> named = <String>[
    lensMap,
    lensCollection,
    lensJourney,
    locked,
    visited,
    revealed,
    unlock,
    addToItinerary,
    removeFromItinerary,
    story,
    questStep,
    myLocation,
    play,
    pause,
    next,
    back,
    questRoute,
    trophy,
    reward,
    camera,
    picture,
    settings,
    themeLight,
    themeDark,
    offline,
    quiz,
    warning,
    placePostOffice,
    placeTower,
    placeWharf,
    placePalace,
    placeMuseum,
    placeMarket,
    placeTomb,
    placeTemple,
  ];

  /// The distinct files that must exist under `assets/icons/`.
  static final Set<String> all = named.toSet();
}
