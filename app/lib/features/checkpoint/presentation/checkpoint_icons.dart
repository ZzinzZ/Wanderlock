import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Which building sticker a place wears — on the map, in the album and in the
/// unlock moment. Section 0 of the art direction.
///
/// Two layers, on purpose. [_byId] gives twelve named places a sticker that is
/// about *them*; the category switch catches everything else, so a place added
/// tomorrow always draws something.
///
/// This is a design decision rather than content, which is why it lives here
/// and not in `checkpoints.json`: the sticker has to stay inside the set the
/// art direction settled on, and picking one is picking how a place reads. If
/// it ever needs to be edited without a build, it moves to the content file
/// and gains a column, and this becomes the fallback.
///
/// The per-category answer is a `switch` rather than a map so that adding a
/// category to [CheckpointCategory] fails to compile until it has been given a
/// sticker. A map with a `??` fallback compiles clean and ships every place of
/// the new kind drawn as a palace, which nothing catches but a person looking
/// at the map.
class CheckpointIcons {
  const CheckpointIcons._();

  static const Map<String, String> _byId = <String, String>{
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

  static String landmarkOf(Checkpoint checkpoint) =>
      _byId[checkpoint.id] ??
      _byName(checkpoint.name) ??
      _byCategory(checkpoint.category);

  /// "Religious" covers pagodas, temples and churches alike; the name is the
  /// only thing that tells a church apart, and a church drawn as a pagoda is
  /// the kind of mistake a local notices at once.
  static String? _byName(String name) =>
      name.startsWith('Nhà thờ') ? LandmarkArt.church : null;

  static String _byCategory(CheckpointCategory category) => switch (category) {
    CheckpointCategory.museum => LandmarkArt.museum,
    // A statue or an obelisk, not a palace: of the monuments added from
    // OSM, almost none are buildings.
    CheckpointCategory.monument => LandmarkArt.obelisk,
    CheckpointCategory.market => LandmarkArt.market,
    CheckpointCategory.religious => LandmarkArt.pagoda,
    CheckpointCategory.architecture => LandmarkArt.tower,
    CheckpointCategory.street => LandmarkArt.postOffice,
    CheckpointCategory.park => LandmarkArt.park,
    CheckpointCategory.shopping => LandmarkArt.mall,
    CheckpointCategory.food => LandmarkArt.food,
    CheckpointCategory.sight => LandmarkArt.camera,
    CheckpointCategory.entertainment => LandmarkArt.theatre,
  };
}
