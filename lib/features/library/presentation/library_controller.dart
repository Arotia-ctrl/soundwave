import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/track.dart';
import '../../scanner/data/scanner_service.dart';

enum LibraryStatus { loading, ready, permissionDenied, error }

enum SortMode { title, artist, album, duration, dateAdded, dateModified }

class TrackGroup {
  final String name;
  final List<Track> tracks;
  const TrackGroup(this.name, this.tracks);
}

class LibraryState {
  final LibraryStatus status;
  final List<Track> tracks;
  final String query;
  final SortMode sort;
  final bool ascending;
  final String? error;

  const LibraryState({
    this.status = LibraryStatus.loading,
    this.tracks = const [],
    this.query = '',
    this.sort = SortMode.title,
    this.ascending = true,
    this.error,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<Track>? tracks,
    String? query,
    SortMode? sort,
    bool? ascending,
    String? error,
  }) {
    return LibraryState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      error: error,
    );
  }

  List<Track> get visibleTracks {
    final q = query.trim().toLowerCase();
    final list = q.isEmpty
        ? List<Track>.of(tracks)
        : tracks.where((t) {
            return t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q) ||
                t.album.toLowerCase().contains(q) ||
                t.genre.toLowerCase().contains(q);
          }).toList();

    int compare(Track a, Track b) {
      switch (sort) {
        case SortMode.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortMode.artist:
          return a.mainArtist.toLowerCase().compareTo(
            b.mainArtist.toLowerCase(),
          );
        case SortMode.album:
          return a.album.toLowerCase().compareTo(b.album.toLowerCase());
        case SortMode.duration:
          return a.durationMs.compareTo(b.durationMs);
        case SortMode.dateAdded:
          return a.dateAdded.compareTo(b.dateAdded);
        case SortMode.dateModified:
          return a.dateModified.compareTo(b.dateModified);
      }
    }

    list.sort((a, b) => ascending ? compare(a, b) : compare(b, a));
    return list;
  }

  List<TrackGroup> get artistGroups => _group((t) => t.mainArtist);

  List<TrackGroup> get albumGroups => _group((t) => t.album);

  List<TrackGroup> _group(String Function(Track) keyOf) {
    final map = <String, List<Track>>{};
    final names = <String, String>{};
    for (final t in visibleTracks) {
      final name = keyOf(t);
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      map.putIfAbsent(key, () => []).add(t);
    }
    final groups = map.entries
        .map((e) => TrackGroup(names[e.key]!, e.value))
        .toList();
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }
}

final scannerServiceProvider = Provider<ScannerService>(
  (ref) => ScannerService(),
);

final libraryProvider = NotifierProvider<LibraryController, LibraryState>(
  LibraryController.new,
);

class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() {
    Future.microtask(scan);
    return const LibraryState();
  }

  Future<void> scan() async {
    final scanner = ref.read(scannerServiceProvider);
    state = state.copyWith(status: LibraryStatus.loading);
    try {
      var granted = await scanner.hasPermission();
      if (!granted) granted = await scanner.requestPermission();
      if (!granted) {
        state = state.copyWith(status: LibraryStatus.permissionDenied);
        return;
      }
      final tracks = await scanner.scan();
      state = state.copyWith(status: LibraryStatus.ready, tracks: tracks);
    } catch (e) {
      state = state.copyWith(status: LibraryStatus.error, error: e.toString());
    }
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(SortMode sort) {
    if (sort == state.sort) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = state.copyWith(sort: sort, ascending: true);
    }
  }
}
