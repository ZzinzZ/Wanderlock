import 'package:flutter/widgets.dart';

import 'package:wanderlock/design/widgets/app_icon.dart';

/// A cartoon sticker of a building, drawn for the sticker pass.
///
/// Provisional artwork, drawn in-house to settle the direction; sources and
/// the generator are in `content/landmarks/`. The art direction expects them
/// to be redrawn by an illustrator. The names are what the code depends on,
/// so the files can be swapped without touching a widget.
class LandmarkArt {
  const LandmarkArt._();

  static const String palace = 'palace';
  static const String postOffice = 'post';
  static const String market = 'market';
  static const String museum = 'museum';
  static const String pagoda = 'pagoda';
  static const String temple = 'temple';
  static const String wharf = 'wharf';
  static const String tower = 'tower';

  static const List<String> all = <String>[
    palace,
    postOffice,
    market,
    museum,
    pagoda,
    temple,
    wharf,
    tower,
  ];

  static String assetPath(String name) => 'assets/landmarks/$name.png';
}

/// Draws one [LandmarkArt], greyed while the place is not yet reached —
/// "colour returns to where you have been", the same rule as [AppIcon].
class LandmarkImage extends StatelessWidget {
  const LandmarkImage(
    this.name, {
    required this.size,
    this.isMuted = false,
    super.key,
  });

  final String name;
  final double size;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      LandmarkArt.assetPath(name),
      width: size,
      height: size,
    );
    if (!isMuted) return image;
    return Opacity(
      opacity: 0.7,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(AppIcon.greyscaleMatrix),
        child: image,
      ),
    );
  }
}
