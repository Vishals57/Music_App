import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../screens/now_playing_screen.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Track> _newReleases = [];
  List<Track> _hindiTracks = [];
  List<Track> _trending = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final releases = await _apiService.getNewReleases();
      final hindiTracks = await _apiService.getHindiTracks();
      final trending = await _apiService.getTrending();

      setState(() {
        _newReleases = _toTracks(releases.data);
        _hindiTracks = _toTracks(hindiTracks.data);
        _trending = _toTracks(trending.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Track> _toTracks(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Track.fromJson)
        .where((track) => track.url.isNotEmpty)
        .toList();
  }

  Future<void> _play(Track track, List<Track> queue) async {
    try {
      await context.read<PlayerService>().playTrack(track, queue: queue);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play this track: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _loadData)
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppTheme.primaryColor,
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          backgroundColor: AppTheme.backgroundColor,
                          floating: true,
                          elevation: 0,
                          title: const Text(
                            'Good listening',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: AppTheme.primaryColor),
                              onPressed: _loadData,
                            ),
                          ],
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              const _SectionHeader(
                                title: 'New & Trending',
                                subtitle:
                                    'Hindi, Marathi, Indian and global songs from free music APIs',
                              ),
                              const SizedBox(height: 12),
                              if (_newReleases.isNotEmpty)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Play All'),
                                        onPressed: () => _play(
                                          _newReleases.first,
                                          _newReleases,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.shuffle),
                                        label: const Text('Shuffle'),
                                        onPressed: () {
                                          final shuffled =
                                              List<Track>.from(_newReleases)
                                                ..shuffle();
                                          _play(shuffled.first, shuffled);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 236,
                                child: _newReleases.isEmpty
                                    ? const _EmptyState(
                                        text: 'No releases found')
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _newReleases.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final track = _newReleases[index];
                                          return _TrackCard(
                                            track: track,
                                            width: 164,
                                            onTap: () =>
                                                _play(track, _newReleases),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 28),
                              const _SectionHeader(
                                title: 'Hindi & Marathi',
                                subtitle:
                                    'Bollywood, Marathi, Punjabi and Indian music previews',
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 236,
                                child: _hindiTracks.isEmpty
                                    ? const _EmptyState(
                                        text: 'No Hindi tracks found')
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _hindiTracks.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final track = _hindiTracks[index];
                                          return _TrackCard(
                                            track: track,
                                            width: 164,
                                            onTap: () =>
                                                _play(track, _hindiTracks),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 28),
                              const _SectionHeader(
                                title: 'Trending Now',
                                subtitle: 'Tap any song to start playback',
                              ),
                              const SizedBox(height: 12),
                              if (_trending.isEmpty)
                                const _EmptyState(text: 'No trending tracks')
                              else
                                ..._trending.take(12).map(
                                      (track) => _TrackTile(
                                        track: track,
                                        queue: _trending,
                                        onPlay: _play,
                                      ),
                                    ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  final double width;
  final VoidCallback onTap;

  const _TrackCard({
    required this.track,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final isFavorite = player.isFavorite(track);

    return SizedBox(
      width: width,
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _Artwork(track: track, size: width - 20),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: onTap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    InkResponse(
                      onTap: () => player.toggleFavorite(track),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final List<Track> queue;
  final Future<void> Function(Track track, List<Track> queue) onPlay;

  const _TrackTile({
    required this.track,
    required this.queue,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final isFavorite = player.isFavorite(track);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _Artwork(track: track, size: 56),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppTheme.primaryColor : AppTheme.textSecondary,
        ),
        onPressed: () => player.toggleFavorite(track),
      ),
      onTap: () => onPlay(track, queue),
    );
  }
}

class _Artwork extends StatelessWidget {
  final Track track;
  final double size;

  const _Artwork({required this.track, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: track.thumbnail.isEmpty
          ? Container(
              width: size,
              height: size,
              color: AppTheme.secondaryColor,
              child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
            )
          : Image.network(
              track.thumbnail,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: AppTheme.secondaryColor,
                child:
                    const Icon(Icons.music_note, color: AppTheme.primaryColor),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
