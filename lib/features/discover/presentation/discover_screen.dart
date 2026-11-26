import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../analyzer/presentation/analysis_controller.dart';
import '../../classification/domain/classifier.dart';
import '../../library/presentation/library_controller.dart';
import '../../library/presentation/widgets/track_tile.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final Set<Mood> _moods = {};
  final Set<TempoCategory> _tempos = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(libraryProvider.select((s) => s.tracks));
    final results = ref.watch(analysisProvider.select((s) => s.results));

    final q = _query.trim().toLowerCase();
    final filtered =
        tracks.where((t) {
          final r = results[t.id];
          final mood = r?.mood ?? Mood.unknown;
          final tempo = r?.tempo ?? TempoCategory.unknown;
          if (_moods.isNotEmpty && !_moods.contains(mood)) return false;
          if (_tempos.isNotEmpty && !_tempos.contains(tempo)) return false;
          if (q.isNotEmpty &&
              !t.title.toLowerCase().contains(q) &&
              !t.artist.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        }).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: ListView.builder(
        itemCount: filtered.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _header(filtered.length);
          final track = filtered[i - 1];
          return TrackTile(track: track, queue: filtered, index: i - 1);
        },
      ),
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalysisCard(),
          const SizedBox(height: 16),
          const Text('Ambiance', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final m in Mood.values)
                FilterChip(
                  label: Text(m.label),
                  selected: _moods.contains(m),
                  onSelected: (on) =>
                      setState(() => on ? _moods.add(m) : _moods.remove(m)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tempo', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final t in const [TempoCategory.slow, TempoCategory.fast])
                FilterChip(
                  label: Text(t.label),
                  selected: _tempos.contains(t),
                  onSelected: (on) =>
                      setState(() => on ? _tempos.add(t) : _tempos.remove(t)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Filtrer par titre ou artiste',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count morceau${count > 1 ? 'x' : ''}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends ConsumerWidget {
  const _AnalysisCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(libraryProvider.select((s) => s.tracks));
    final state = ref.watch(analysisProvider);
    final controller = ref.read(analysisProvider.notifier);

    final analyzed = state.results.values.where((r) => r.analyzed).length;
    final pending = tracks
        .where((t) => AnalysisController.needsAnalysis(state.results[t.id]))
        .length;
    final progress = tracks.isEmpty ? 0.0 : analyzed / tracks.length;
    final running = state.phase == AnalysisPhase.running;

    final String status;
    if (running) {
      status = 'Analyse en cours : ${state.done} / ${state.total}';
    } else if (tracks.isNotEmpty && pending == 0) {
      status = 'Toute la bibliothèque est analysée';
    } else if (state.phase == AnalysisPhase.paused) {
      status = 'Analyse suspendue';
    } else {
      status = 'Analyse du rythme et de l\'ambiance';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$analyzed / ${tracks.length} morceaux analysés',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (running)
                FilledButton.icon(
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Suspendre'),
                )
              else if (pending > 0)
                FilledButton.icon(
                  onPressed: controller.start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(analyzed > 0 ? 'Continuer' : 'Analyser'),
                ),
              const Spacer(),
              TextButton(
                onPressed: controller.reclassifyAll,
                child: const Text('Recalculer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
