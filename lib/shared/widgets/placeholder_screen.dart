import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.elevated,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
