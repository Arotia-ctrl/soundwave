import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../analyzer/presentation/analysis_controller.dart';
import '../../library/data/user_data_providers.dart';
import '../../library/presentation/library_controller.dart';
import '../../playlists/data/playlist_providers.dart';
import '../data/data_maintenance_repository.dart';
import '../data/settings_controller.dart';
import '../data/system_service.dart';

const Color _danger = Color(0xFFFF6B6B);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Au retour des paramètres Android, on relit l'état des permissions
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(permissionInfoProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: _danger)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _reloadUserData() {
    ref.invalidate(favoritesProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(playlistsProvider);
    ref.invalidate(analysisProvider);
  }

  Future<void> _cleanOrphans() async {
    final library = ref.read(libraryProvider);
    if (library.status != LibraryStatus.ready || library.tracks.isEmpty) {
      _toast("Lance d'abord un scan de la bibliothèque.");
      return;
    }
    final existing = {for (final t in library.tracks) t.id};
    final repo = ref.read(dataMaintenanceProvider);

    final count = await repo.countOrphans(existing);
    if (!mounted) return;
    if (count == 0) {
      _toast('Aucune donnée orpheline.');
      return;
    }

    final ok = await _confirm(
      title: 'Nettoyer les données ?',
      message:
          '$count éléments (favoris, historique, playlists, analyses) '
          'concernent des fichiers absents de ta bibliothèque.\n\n'
          "Si tu utilises une carte SD, vérifie qu'elle est bien insérée : "
          'sinon ses morceaux apparaîtraient aussi comme absents.',
      action: 'Nettoyer',
    );
    if (!ok) return;

    await repo.purgeOrphans(existing);
    _reloadUserData();
    _toast('Données nettoyées.');
  }

  Future<void> _resetAll() async {
    if (ref.read(analysisProvider).phase == AnalysisPhase.running) {
      _toast("Suspends d'abord l'analyse (onglet Discover).");
      return;
    }
    final ok = await _confirm(
      title: 'Réinitialiser les données ?',
      message:
          'Favoris, playlists, historique, analyses et corrections '
          'manuelles seront effacés.\n\n'
          'Tes fichiers audio et tes réglages ne sont pas touchés. '
          'Cette action est définitive.',
      action: 'Tout effacer',
      destructive: true,
    );
    if (!ok) return;

    await ref.read(dataMaintenanceProvider).resetAll();
    _reloadUserData();
    _toast('Données réinitialisées.');
  }

  Future<void> _clearHistory() async {
    final ok = await _confirm(
      title: "Effacer l'historique ?",
      message: "Les listes Recently Played et Most Played seront vidées.",
      action: 'Effacer',
    );
    if (!ok) return;
    await ref.read(historyProvider.notifier).clear();
    _toast('Historique effacé.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final permissions = ref.watch(permissionInfoProvider).value;
    final library = ref.watch(libraryProvider);
    final analysis = ref.watch(analysisProvider);
    final analysisNotifier = ref.read(analysisProvider.notifier);
    final history = ref.watch(historyProvider);
    final system = ref.read(systemServiceProvider);

    final failedCount = analysis.results.values
        .where((r) => r.status == 'failed')
        .length;
    final plays = history.counts.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: ListView(
        children: [
          const _Section('Apparence'),
          const ListTile(
            leading: Icon(Icons.palette_rounded, color: AppColors.accent),
            title: Text('Thème'),
            subtitle: Text('Dark Purple'),
          ),

          const _Section('Permissions'),
          ListTile(
            leading: const Icon(
              Icons.library_music_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Accès à la musique'),
            subtitle: Text(
              permissions == null
                  ? '…'
                  : (permissions.media ? 'Autorisé' : 'Refusé'),
            ),
            trailing: (permissions != null && !permissions.media)
                ? TextButton(
                    onPressed: () async {
                      await ref
                          .read(scannerServiceProvider)
                          .requestPermission();
                      ref.invalidate(permissionInfoProvider);
                    },
                    child: const Text('Autoriser'),
                  )
                : null,
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Notifications de lecture'),
            subtitle: Text(
              permissions == null
                  ? '…'
                  : (permissions.notifications ? 'Activées' : 'Désactivées'),
            ),
            trailing: TextButton(
              onPressed: system.openNotificationSettings,
              child: const Text('Réglages'),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_applications_rounded,
              color: AppColors.accent,
            ),
            title: const Text("Paramètres Android de l'application"),
            onTap: system.openAppSettings,
          ),

          const _Section('Bibliothèque'),
          ListTile(
            leading: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            title: const Text('Scanner maintenant'),
            subtitle: Text(
              '${library.tracks.length} morceau${library.tracks.length > 1 ? 'x' : ''} trouvés',
            ),
            onTap: () async {
              await ref.read(libraryProvider.notifier).scan();
              _toast(
                '${ref.read(libraryProvider).tracks.length} morceaux trouvés',
              );
            },
          ),

          const _Section('Lecture'),
          SwitchListTile(
            secondary: const Icon(
              Icons.restore_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Reprendre la lecture au lancement'),
            subtitle: const Text('Retrouve le dernier morceau et sa position'),
            value: settings.resumePlayback,
            onChanged: settingsNotifier.setResumePlayback,
          ),
          ListTile(
            leading: const Icon(Icons.timer_rounded, color: AppColors.accent),
            title: const Text('Écoute comptée après'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 5, label: Text('5 s')),
                  ButtonSegment(value: 15, label: Text('15 s')),
                  ButtonSegment(value: 30, label: Text('30 s')),
                ],
                selected: {settings.historySeconds},
                onSelectionChanged: (s) =>
                    settingsNotifier.setHistorySeconds(s.first),
              ),
            ),
          ),

          const _Section('Analyse'),
          SwitchListTile(
            secondary: const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Analyse automatique'),
            subtitle: const Text(
              'Analyse les nouveaux morceaux dès que possible, en arrière-plan',
            ),
            value: settings.autoAnalysis,
            onChanged: settingsNotifier.setAutoAnalysis,
          ),
          ListTile(
            leading: const Icon(Icons.replay_rounded, color: AppColors.accent),
            title: const Text('Retenter les morceaux en échec'),
            subtitle: Text(
              failedCount == 0
                  ? 'Aucun échec'
                  : '$failedCount morceau${failedCount > 1 ? 'x' : ''}',
            ),
            enabled: failedCount > 0 && analysis.phase != AnalysisPhase.running,
            onTap: analysisNotifier.retryFailed,
          ),
          ListTile(
            leading: const Icon(
              Icons.calculate_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Recalculer les catégories'),
            subtitle: const Text(
              'Réapplique les seuils sans réanalyser les fichiers',
            ),
            onTap: () async {
              await analysisNotifier.reclassifyAll();
              _toast('Catégories recalculées.');
            },
          ),

          const _Section('Données'),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppColors.accent),
            title: const Text("Effacer l'historique d'écoute"),
            subtitle: Text(
              '$plays écoute${plays > 1 ? 's' : ''} enregistrée${plays > 1 ? 's' : ''}',
            ),
            enabled: plays > 0,
            onTap: _clearHistory,
          ),
          ListTile(
            leading: const Icon(
              Icons.cleaning_services_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Nettoyer les données orphelines'),
            subtitle: const Text(
              'Supprime ce qui concerne des fichiers disparus',
            ),
            onTap: _cleanOrphans,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: _danger),
            title: const Text(
              'Réinitialiser les données locales',
              style: TextStyle(color: _danger),
            ),
            subtitle: const Text('Favoris, playlists, historique, analyses'),
            onTap: _resetAll,
          ),

          const _Section('À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded, color: AppColors.accent),
            title: Text('$appName $appVersion'),
            subtitle: Text('$appTagline\nTout reste sur ton téléphone.'),
            isThreeLine: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
