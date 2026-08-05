import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/neumorphic_surface.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Lists the pilot's checkpoints.
///
/// Placeholder for F2: the real presentation is the full-screen map in F3.
/// Its job here is to prove the chain works — server to cache to screen — and
/// that pulling the network out changes nothing the user can see.
class CheckpointListScreen extends ConsumerStatefulWidget {
  const CheckpointListScreen({super.key});

  @override
  ConsumerState<CheckpointListScreen> createState() =>
      _CheckpointListScreenState();
}

class _CheckpointListScreenState extends ConsumerState<CheckpointListScreen> {
  @override
  void initState() {
    super.initState();
    // Fire and forget: the list is already being served from cache, so the
    // refresh has nothing to block.
    Future.microtask(
      () => ref.read(checkpointRefreshProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final checkpoints = ref.watch(checkpointsProvider);
    final lastRefresh = ref.watch(checkpointRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkpointsTitle),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(checkpointRefreshProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.checkpointsRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lastRefresh == RefreshOutcome.servedFromCache)
              _OfflineBanner(message: l10n.checkpointsOffline),
            Expanded(
              child: checkpoints.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                // An error here means the cache itself failed, which is a real
                // fault — a network failure never reaches this branch.
                error: (error, _) =>
                    _Message(text: l10n.checkpointsError, color: colors.coral),
                data: (list) => list.isEmpty
                    ? _Message(
                        text: l10n.checkpointsEmpty,
                        color: colors.inkMuted,
                      )
                    : _CheckpointList(checkpoints: list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckpointList extends StatelessWidget {
  const _CheckpointList({required this.checkpoints});

  final List<Checkpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      itemCount: checkpoints.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          _CheckpointTile(checkpoint: checkpoints[index]),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  const _CheckpointTile({required this.checkpoint});

  final Checkpoint checkpoint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return NeumorphicSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checkpoint.name, style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  checkpoint.address ?? checkpoint.category.name,
                  style: AppTypography.label.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${checkpoint.radiusMeters} m',
            style: AppTypography.numeric.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ColoredBox(
      color: colors.accentYellow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: colors.onAccentYellow),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: color),
        ),
      ),
    );
  }
}
