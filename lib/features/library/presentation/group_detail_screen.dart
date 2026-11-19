import 'package:flutter/material.dart';

import '../../../shared/models/track.dart';
import 'widgets/track_tile.dart';

class GroupDetailScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;

  const GroupDetailScreen({
    super.key,
    required this.title,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, i) =>
            TrackTile(track: tracks[i], queue: tracks, index: i),
      ),
    );
  }
}
