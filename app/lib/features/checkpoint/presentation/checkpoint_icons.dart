import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Which 3D icon stands for a place.
///
/// Two layers, on purpose. [_byId] gives twelve named places an icon that is
/// about *them* — a letter for the post office, a rocket for the tower, a
/// suitcase for the wharf people sailed from. [_byCategory] catches everything
/// else, so a place added tomorrow always draws something.
///
/// This is a design decision rather than content, which is why it lives here
/// and not in `checkpoints.json`: the icon has to stay inside the set the art
/// direction settled on, and picking one is picking how a place reads. If it
/// ever needs to be edited without a build — a city with two hundred places,
/// say — it moves to the content file and gains a column, and this map becomes
/// the fallback.
class CheckpointIcons {
  const CheckpointIcons._();

  /// The named twelve of the pilot.
  ///
  /// Deliberately not "one icon per category". A market, a market, a museum
  /// and a palace drawn as four generic pins is a legend, not a map — these
  /// are chosen so the shape of the city is readable before a single label is.
  static const Map<String, String> _byId = <String, String>{
    // The letter is the building's whole reason for existing.
    'central-post-office': AppIcons.placePostOffice,
    // 461 m, and the only thing on this map that points straight up.
    'landmark-81': AppIcons.placeTower,
    // The wharf people sailed from.
    'nha-rong-wharf': AppIcons.placeWharf,
    // Seat of government: the flag, not the building.
    'independence-palace': AppIcons.placePalace,
    // A museum of photographs, and remembered as photographs.
    'war-remnants-museum': AppIcons.placeMuseum,
    // The two big markets.
    'ben-thanh-market': AppIcons.placeMarket,
    'binh-tay-market': AppIcons.placeMarket,
    // The mausoleum of a marshal.
    'le-van-duyet-tomb': AppIcons.placeTomb,
    // Incense, which is what you smell before you see any of the four.
    'thien-hau-temple': AppIcons.placeTemple,
    'vinh-nghiem-pagoda': AppIcons.placeTemple,
    'giac-lam-pagoda': AppIcons.placeTemple,
    'buu-long-pagoda': AppIcons.placeTemple,
  };

  static const Map<CheckpointCategory, String> _byCategory =
      <CheckpointCategory, String>{
        CheckpointCategory.museum: AppIcons.placeMuseum,
        CheckpointCategory.monument: AppIcons.placePalace,
        CheckpointCategory.market: AppIcons.placeMarket,
        CheckpointCategory.religious: AppIcons.placeTemple,
        CheckpointCategory.architecture: AppIcons.placeTower,
        CheckpointCategory.street: AppIcons.lensMap,
        CheckpointCategory.park: AppIcons.themeLight,
        CheckpointCategory.shopping: AppIcons.placeMarket,
        CheckpointCategory.food: AppIcons.placeTemple,
        CheckpointCategory.sight: AppIcons.camera,
        CheckpointCategory.entertainment: AppIcons.reward,
      };

  static String of(Checkpoint checkpoint) =>
      _byId[checkpoint.id] ??
      _byCategory[checkpoint.category] ??
      AppIcons.lensMap;

  /// Every icon a marker might ask for, so they can all be registered with the
  /// map before any of them is drawn.
  static Set<String> get all => <String>{
    ..._byId.values,
    ..._byCategory.values,
    AppIcons.lensMap,
  };

  /// The building sticker a place wears on the map, in the album and in the
  /// unlock moment — section 0 of the art direction. Same two layers as the
  /// icon: the twelve by name, everything else by category.
  static const Map<String, String> _landmarkById = <String, String>{
    'independence-palace': LandmarkArt.palace,
    'central-post-office': LandmarkArt.postOffice,
    'ben-thanh-market': LandmarkArt.market,
    'binh-tay-market': LandmarkArt.market,
    'war-remnants-museum': LandmarkArt.museum,
    'vinh-nghiem-pagoda': LandmarkArt.pagoda,
    'giac-lam-pagoda': LandmarkArt.pagoda,
    'buu-long-pagoda': LandmarkArt.pagoda,
    'le-van-duyet-tomb': LandmarkArt.temple,
    'thien-hau-temple': LandmarkArt.temple,
    'nha-rong-wharf': LandmarkArt.wharf,
    'landmark-81': LandmarkArt.tower,
  };

  static const Map<CheckpointCategory, String> _landmarkByCategory =
      <CheckpointCategory, String>{
        CheckpointCategory.museum: LandmarkArt.museum,
        // A statue or an obelisk, not a palace: of the monuments added from
        // OSM, almost none are buildings.
        CheckpointCategory.monument: LandmarkArt.obelisk,
        CheckpointCategory.market: LandmarkArt.market,
        CheckpointCategory.religious: LandmarkArt.pagoda,
        CheckpointCategory.architecture: LandmarkArt.tower,
        CheckpointCategory.street: LandmarkArt.postOffice,
        CheckpointCategory.park: LandmarkArt.park,
        CheckpointCategory.shopping: LandmarkArt.mall,
        CheckpointCategory.food: LandmarkArt.food,
        CheckpointCategory.sight: LandmarkArt.camera,
        CheckpointCategory.entertainment: LandmarkArt.theatre,
      };

  static String landmarkOf(Checkpoint checkpoint) =>
      _landmarkById[checkpoint.id] ??
      _byName(checkpoint.name) ??
      _landmarkByCategory[checkpoint.category] ??
      LandmarkArt.palace;

  /// "Religious" covers pagodas, temples and churches alike; the name is the
  /// only thing that tells a church apart, and a church drawn as a pagoda is
  /// the kind of mistake a local notices at once.
  static String? _byName(String name) =>
      name.startsWith('Nhà thờ') ? LandmarkArt.church : null;
}
