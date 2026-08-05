import 'package:go_router/go_router.dart';

import 'package:wanderlock/app/routes.dart';
import 'package:wanderlock/app/screens/home_screen.dart';
import 'package:wanderlock/app/screens/type_specimen_screen.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_list_screen.dart';
import 'package:wanderlock/features/checkpoint/presentation/map_screen.dart';

/// Application router.
///
/// Two placeholder screens for F1. Feature routes are added by the phase that
/// owns them, so this file stays the only place that knows the route graph.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
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
