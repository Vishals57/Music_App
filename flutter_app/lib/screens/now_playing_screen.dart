import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../services/player_service.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final track = player.currentTrack;

    if (track == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text('Nothing is playing',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    if (player.isPlaying && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!player.isPlaying && _animationController.isAnimating) {
      _animationController.stop();
    }

    final duration = player.duration;
    final position = player.position > duration && duration != Duration.zero
        ? duration
        : player.position;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.expand_more,
                        color: AppTheme.textPrimary, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Now Playing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      player.isFavorite(track)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => player.toggleFavorite(track),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: RotationTransition(
                  turns: _animationController,
                  child: _AlbumArt(track: track),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds <= 0
                        ? 1
                        : duration.inMilliseconds.toDouble(),
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.secondaryColor,
                    onChanged: (value) =>
                        player.seek(Duration(milliseconds: value.toInt())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(position),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      Text(_format(duration),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: player.shuffle
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        onPressed: player.toggleShuffle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            color: AppTheme.textPrimary, size: 34),
                        onPressed: player.previous,
                      ),
                      InkResponse(
                        onTap: player.togglePlayPause,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next,
                            color: AppTheme.textPrimary, size: 34),
                        onPressed: player.next,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.repeat_one,
                          color: player.loopMode == LoopMode.one
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        onPressed: player.toggleRepeat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Icon(Icons.volume_down,
                          color: AppTheme.textSecondary, size: 20),
                      Expanded(
                        child: Slider(
                          value: player.volume,
                          min: 0,
                          max: 1,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: AppTheme.secondaryColor,
                          onChanged: player.setVolume,
                        ),
                      ),
                      const Icon(Icons.volume_up,
                          color: AppTheme.textSecondary, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final Track track;

  const _AlbumArt({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 292,
      height: 292,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 42,
            spreadRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: track.thumbnail.isEmpty
            ? Container(
                color: AppTheme.secondaryColor,
                child: const Icon(Icons.album,
                    size: 132, color: AppTheme.primaryColor),
              )
            : Image.network(
                track.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.secondaryColor,
                  child: const Icon(Icons.album,
                      size: 132, color: AppTheme.primaryColor),
                ),
              ),
      ),
    );
  }
}
