import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/playlist_providers.dart';
import 'playlist_detail_screen.dart';
import 'widgets/playlist_dialogs.dart';

String _count(int n) => '$n morceau${n > 1 ? 'x' : ''}';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autos = ref.watch(autoPlaylistsProvider);
    final playlists = ref.watch(playlistsProvider);
    final notifier = ref.read(playlistsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Playlists',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nouvelle playlist',
            onPressed: () async {
              final name = await askPlaylistName(context);
              if (name != null && name.isNotEmpty) await notifier.create(name);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const _SectionTitle('Automatiques'),
          for (final a in autos)
            ListTile(
              leading: _IconBox(a.icon),
              title: Text(
                a.name,
                style: const TextStyle(color: AppColors.text),
              ),
              subtitle: Text(_count(a.tracks.length)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(autoKey: a.key),
                ),
              ),
            ),
          const _SectionTitle('Mes playlists'),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text('Aucune playlist. Appuie sur + pour en créer une.'),
            ),
          for (final p in playlists)
            ListTile(
              leading: const _IconBox(Icons.queue_music_rounded),
              title: Text(
                p.name,
                style: const TextStyle(color: AppColors.text),
              ),
              subtitle: Text(_count(p.trackIds.length)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                ),
                color: AppColors.elevated,
                onSelected: (value) async {
                  if (value == 'rename') {
                    final name = await askPlaylistName(
                      context,
                      title: 'Renommer la playlist',
                      initial: p.name,
                    );
                    if (name != null && name.isNotEmpty) {
                      await notifier.rename(p.id, name);
                    }
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.elevated,
                        title: const Text('Supprimer la playlist ?'),
                        content: Text(
                          '« ${p.name} » sera supprimée. Tes fichiers audio ne sont pas touchés.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await notifier.delete(p.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Renommer')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlistId: p.id),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.accent),
    );
  }
}
