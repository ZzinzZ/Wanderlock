import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/map/camera_projection.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/player_dot.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_map_canvas.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Says out loud that this build has no server behind it.
///
/// A demonstration that quietly looks like the real thing is how a stand-in
/// ends up being mistaken for a verified unlock. It is cheap to label and
/// expensive to explain later.
class StandInBanner extends StatelessWidget {
  const StandInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentYellow,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
        boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          l10n.standInModeBadge,
          style: AppTypography.tag.copyWith(color: colors.onAccentYellow),
        ),
      ),
    );
  }
}

/// Draws the pan explorer where it stands on the map — usually the centre,
/// but not while a zoom is under way, which is the point: zooming does not
/// move the player.
class ExplorerLayer extends StatelessWidget {
  const ExplorerLayer({
    required this.controller,
    required this.explorer,
    super.key,
  });

  final MapLibreMapController controller;
  final ValueListenable<TrailPoint?> explorer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([controller, explorer]),
        builder: (context, _) {
          final camera =
              controller.cameraPosition ?? CheckpointMapCanvas.initialCamera;
          final at = explorer.value;
          final projection = camera.projectionOver(constraints.biggest);
          final screen = at == null
              ? (x: constraints.maxWidth / 2, y: constraints.maxHeight / 2)
              : projection.toScreen(at.latitude, at.longitude);

          return Stack(
            children: [
              Positioned(
                left: screen.x - AppIconSize.inline / 2,
                top: screen.y - AppIconSize.inline / 2,
                child: const PlayerDot(),
              ),
            ],
          );
        },
      ),
    );
  }
}
