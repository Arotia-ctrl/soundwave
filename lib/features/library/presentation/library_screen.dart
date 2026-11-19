import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Library',
      icon: Icons.library_music_rounded,
      subtitle: 'Ta bibliothèque apparaîtra ici',
    );
  }
}
