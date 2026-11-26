import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/track.dart';
import '../../data/playlist_providers.dart';

/// Demande un nom. Renvoie null si annulé, ou une chaîne (possiblement vide).
Future<String?> askPlaylistName(
  BuildContext context, {
  String title = 'Nouvelle playlist',
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.elevated,
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Nom de la playlist'),
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}

/// Feuille « Ajouter à une playlist » pour un morceau.
void showAddToPlaylistSheet(BuildContext context, Track track) {
  final messenger = ScaffoldMessenger.of(context);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => Consumer(
      builder: (_, ref, _) {
        final playlists = ref.watch(playlistsProvider);
        final notifier = ref.read(playlistsProvider.notifier);

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add_rounded, color: AppColors.accent),
                title: const Text('Nouvelle playlist'),
                onTap: () async {
                  final name = await askPlaylistName(sheetContext);
                  if (name == null || name.isEmpty) return;
                  final id = await notifier.create(name);
                  if (id != null) await notifier.addTrack(id, track.id);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Ajouté à « $name »')),
                  );
                },
              ),
              for (final p in playlists)
                ListTile(
                  leading: const Icon(
                    Icons.queue_music_rounded,
                    color: AppColors.textMuted,
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    p.trackIds.contains(track.id)
                        ? 'Déjà dans cette playlist'
                        : '${p.trackIds.length} morceau${p.trackIds.length > 1 ? 'x' : ''}',
                  ),
                  onTap: () async {
                    final already = p.trackIds.contains(track.id);
                    if (!already) await notifier.addTrack(p.id, track.id);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          already
                              ? 'Déjà dans « ${p.name} »'
                              : 'Ajouté à « ${p.name} »',
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
