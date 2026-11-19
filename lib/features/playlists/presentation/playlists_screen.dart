import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Playlists',
      icon: Icons.queue_music_rounded,
      subtitle: 'Tes playlists seront listées ici',
    );
  }
}
