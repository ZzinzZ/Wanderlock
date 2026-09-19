import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';
import 'package:wanderlock/features/itinerary/application/itinerary_providers.dart';
import 'package:wanderlock/features/itinerary/presentation/itinerary_editor.dart';
import 'package:wanderlock/features/quest/presentation/quest_panel.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The Journey tab: a curated route, and the user's own.
///
/// Lives in `app/lenses/` and not in either feature, because it is the one
/// widget that has to know both exist — and a feature knowing about another
/// feature is exactly what the architecture gate rejects. Same reason
/// `ExploreScreen` composes fog and collection instead of either of them
/// reaching for the other.
class JourneyPanel extends ConsumerStatefulWidget {
  const JourneyPanel({super.key});

  @override
  ConsumerState<JourneyPanel> createState() => _JourneyPanelState();
}

class _JourneyPanelState extends ConsumerState<JourneyPanel> {
  /// Quest first on a cold open. A new user has no itinerary and an empty list
  /// is a poor first impression of a tab; the authored route at least shows
  /// what the tab is for.
  _JourneyTab _tab = _JourneyTab.quest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          // The lens title as a yellow ribbon, same as the album's.
          child: StickerSurface(
            color: colors.accentYellow,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon(AppIcons.questRoute),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.lensJourney.toUpperCase(),
                  style: AppTypography.banner.copyWith(
                    color: colors.onAccentYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _TabPill(
            current: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _JourneyTab.quest => QuestPanel(
              route: ref.watch(questRouteProvider),
              landmarkOf: CheckpointIcons.landmarkOfId,
            ),
            _JourneyTab.itinerary => ItineraryEditor(
              entries: ref.watch(itineraryEntriesProvider),
              onReorder: (ids) =>
                  ref.read(itineraryControllerProvider).reorder(ids),
              onRemove: (id) =>
                  ref.read(itineraryControllerProvider).remove(id),
              onClear: () => ref.read(itineraryControllerProvider).clear(),
            ),
          },
        ),
        // Room for the lens switcher, which floats over this panel.
        //
        // The bar is roughly 52dp tall and sits `lg` above the safe area, so
        // `xxl` alone left it covering the last row of a full plan. This is
        // that height plus its offset.
        const SizedBox(height: AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg),
      ],
    );
  }
}

enum _JourneyTab { quest, itinerary }

/// The inner switch, built to match the lens switcher rather than to match
/// Material.
///
/// A stock `SegmentedButton` sits directly under the lens pill and would be
/// the only control in the app wearing the framework's own outline — which is
/// exactly the "generic component set" look section 10 of the art direction
/// rules out. Same track, same selected card, same pill radius.
class _TabPill extends StatelessWidget {
  const _TabPill({required this.current, required this.onSelected});

  final _JourneyTab current;
  final ValueChanged<_JourneyTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.stroke),
        boxShadow: AppShadows.sticker(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs + 1),
        child: Row(
          children: [
            for (final (tab, label) in <(_JourneyTab, String)>[
              (_JourneyTab.quest, l10n.journeyTabQuest),
              (_JourneyTab.itinerary, l10n.journeyTabItinerary),
            ])
              Expanded(
                child: Semantics(
                  selected: tab == current,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onSelected(tab),
                    child: AnimatedContainer(
                      duration: AppMotion.lensSwitch,
                      curve: AppMotion.linearCurve,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: tab == current
                            ? colors.accentYellow
                            : colors.card,
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: tab == current ? colors.outline : colors.card,
                          width: AppSticker.strokeThin,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.tab.copyWith(
                          color: tab == current
                              ? colors.onAccentYellow
                              : colors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
