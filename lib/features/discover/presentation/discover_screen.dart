import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Discover',
      icon: Icons.explore_rounded,
      subtitle: 'Catégories Soft / Non-soft à venir',
    );
  }
}
