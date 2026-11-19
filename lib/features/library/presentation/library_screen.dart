import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'group_detail_screen.dart';
import 'library_controller.dart';
import 'widgets/track_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const _sortLabels = {
    SortMode.title: 'Titre',
    SortMode.artist: 'Artiste',
    SortMode.album: 'Album',
    SortMode.duration: 'Durée',
    SortMode.dateAdded: "Date d'ajout",
    SortMode.dateModified: 'Date de modification',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final controller = ref.read(libraryProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Library',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            PopupMenuButton<SortMode>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Trier',
              onSelected: controller.setSort,
              itemBuilder: (context) => [
                for (final mode in SortMode.values)
                  PopupMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Expanded(child: Text(_sortLabels[mode]!)),
                        if (state.sort == mode)
                          Icon(
                            state.ascending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Scanner à nouveau',
              onPressed: controller.scan,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: _buildBody(context, state, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryState state,
    LibraryController controller,
  ) {
    switch (state.status) {
      case LibraryStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );

      case LibraryStatus.permissionDenied:
        return _Message(
          icon: Icons.lock_outline_rounded,
          text:
              "SOUNDWAVE a besoin d'accéder à ta musique.\n"
              "Si la fenêtre ne s'affiche plus, autorise l'accès dans "
              "Paramètres Android > Applications > soundwave > Autorisations.",
          buttonLabel: 'Autoriser',
          onPressed: controller.scan,
        );

      case LibraryStatus.error:
        return _Message(
          icon: Icons.error_outline_rounded,
          text: 'Erreur pendant le scan :\n${state.error}',
          buttonLabel: 'Réessayer',
          onPressed: controller.scan,
        );

      case LibraryStatus.ready:
        if (state.tracks.isEmpty) {
          return _Message(
            icon: Icons.music_off_rounded,
            text: 'Aucun morceau trouvé sur ce téléphone.',
            buttonLabel: 'Scanner à nouveau',
            onPressed: controller.scan,
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: controller.setQuery,
                decoration: InputDecoration(
                  hintText: 'Rechercher un titre, artiste, album, genre',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _songsTab(context, state),
                  _groupsTab(context, state.artistGroups, Icons.person_rounded),
                  _groupsTab(context, state.albumGroups, Icons.album_rounded),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _songsTab(BuildContext context, LibraryState state) {
    final tracks = state.visibleTracks;
    if (tracks.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, i) => TrackTile(
        track: tracks[i],
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La lecture arrive à l'étape 3")),
        ),
      ),
    );
  }

  Widget _groupsTab(
    BuildContext context,
    List<TrackGroup> groups,
    IconData icon,
  ) {
    if (groups.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.elevated,
            child: Icon(icon, color: AppColors.accent),
          ),
          title: Text(
            g.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.text),
          ),
          subtitle: Text(
            '${g.tracks.length} morceau${g.tracks.length > 1 ? 'x' : ''}',
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  GroupDetailScreen(title: g.name, tracks: g.tracks),
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _Message({
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
