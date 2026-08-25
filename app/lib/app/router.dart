import 'package:go_router/go_router.dart';

import 'package:wanderlock/app/routes.dart';
import 'package:wanderlock/app/screens/explore_screen.dart';
import 'package:wanderlock/app/screens/home_screen.dart';
import 'package:wanderlock/app/screens/type_specimen_screen.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_list_screen.dart';
import 'package:wanderlock/features/checkpoint/presentation/map_screen.dart';

/// Application router.
///
/// [initialLocation] is a seam for tests. The explore screen builds a MapLibre
/// platform view, which a widget test cannot render — so the tests that check
/// routing and theming start on the shell instead of pretending to open a map.
///
/// The explore screen is the product: one map, seen through a lens. The F1
/// shell and the bare map are still routed because both remain useful to look
/// at on their own — the shell for type and theming, the map for the style
/// with nothing drawn over it.
GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.shell,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.typeSpecimen,
        builder: (context, state) => const TypeSpecimenScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkpoints,
        builder: (context, state) => const CheckpointListScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
    ],
  );
}
