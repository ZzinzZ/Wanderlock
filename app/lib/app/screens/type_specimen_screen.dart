import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wanderlock/app/routes.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Renders `ế ỡ ộ ữ ẫ` at every bundled weight of both families.
///
/// This screen exists for a Definition of Done item: diacritics are checked by
/// eye on a real device, because stacked marks fail in ways no unit test sees —
/// clipped tone marks, marks colliding with the letter, wrong vertical metrics.
/// They usually break first at the heaviest weight, so every shipped weight is
/// on screen rather than a representative sample.
class TypeSpecimenScreen extends StatelessWidget {
  const TypeSpecimenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.typeSpecimenTitle),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.lg,
          ),
          children: [
            Text(
              l10n.typeSpecimenIntro,
              style: AppTypography.body.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SectionLabel(l10n.uiFontLabel),
            for (final weight in AppTypography.uiWeights)
              _SpecimenRow(
                weightLabel: '${weight.value}',
                sample: l10n.diacriticsSample,
                sentence: l10n.diacriticsSentence,
                style: AppTypography.specimenUi(weight),
              ),

            const SizedBox(height: AppSpacing.xl),

            _SectionLabel(l10n.displayFontLabel),
            for (final weight in AppTypography.displayWeights)
              _SpecimenRow(
                weightLabel: '${weight.toInt()}',
                sample: l10n.diacriticsSample,
                sentence: l10n.diacriticsSentence,
                style: AppTypography.specimenDisplay(weight),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: AppTypography.screenTitle),
    );
  }
}

class _SpecimenRow extends StatelessWidget {
  const _SpecimenRow({
    required this.weightLabel,
    required this.sample,
    required this.sentence,
    required this.style,
  });

  final String weightLabel;
  final String sample;
  final String sentence;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weightLabel,
            style: AppTypography.numeric.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(sample, style: style.copyWith(color: colors.ink)),
          Text(sentence, style: style.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}
