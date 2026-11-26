import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/track.dart';
import '../../classification/domain/classifier.dart';
import 'analysis_controller.dart';

void showAnalysisSheet(BuildContext context, Track track) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (_) => _AnalysisSheet(track: track),
  );
}

class _AnalysisSheet extends ConsumerWidget {
  final Track track;
  const _AnalysisSheet({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      analysisProvider.select((s) => s.results[track.id]),
    );
    final controller = ref.read(analysisProvider.notifier);

    final mood = result?.mood ?? Mood.unknown;
    final overridden = result?.manuallyOverridden ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(track.artist),
            const SizedBox(height: 20),
            if (result != null && result.analyzed) ...[
              _Row('BPM (estimé)', '${result.bpm!.round()}'),
              _Row('Énergie', '${(result.energy! * 100).round()} %'),
              _Row(
                'Volume moyen',
                '${result.loudness!.toStringAsFixed(1)} dBFS',
              ),
              _Row(
                'Plage dynamique',
                '${result.dynamicRange!.toStringAsFixed(1)} dB',
              ),
              _Row(
                'Brillance du son',
                '${result.spectralCentroid!.round()} Hz',
              ),
              _Row(
                'Régularité du rythme',
                '${(result.rhythmStrength! * 100).round()} %',
              ),
              _Row('Tempo', result.tempo.label),
              _Row(
                'Confiance',
                '${((result.confidence ?? 0) * 100).round()} %',
              ),
            ] else
              Text(
                result?.status == 'failed'
                    ? "Ce morceau n'a pas pu être analysé."
                    : "Ce morceau n'a pas encore été analysé.",
              ),
            const SizedBox(height: 20),
            Text(
              'Ambiance : ${mood.label}${overridden ? ' (choisie par toi)' : ''}',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<Mood>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Mood.soft, label: Text('Soft')),
                ButtonSegment(value: Mood.nonSoft, label: Text('Non-soft')),
              ],
              selected: {if (mood == Mood.soft || mood == Mood.nonSoft) mood},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  controller.setManualMood(track.id, selection.first);
                }
              },
            ),
            if (overridden)
              TextButton(
                onPressed: () => controller.clearManualMood(track.id),
                child: const Text("Laisser l'analyse décider"),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(color: AppColors.text)),
        ],
      ),
    );
  }
}
