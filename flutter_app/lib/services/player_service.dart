import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final List<Track> _queue = [];
  final List<Track> _favorites = [];
  final List<Track> _recentlyPlayed = [];

  Track? _currentTrack;
  int _currentIndex = -1;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;

  PlayerService() {
    _loadFavorites();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _loopMode != LoopMode.one) {
        next();
      }
      notifyListeners();
    });
    _audioPlayer.positionStream.listen((_) => notifyListeners());
    _audioPlayer.durationStream.listen((_) => notifyListeners());
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  List<Track> get queue => List.unmodifiable(_queue);
  List<Track> get favorites => List.unmodifiable(_favorites);
  List<Track> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  double get volume => _audioPlayer.volume;

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    if (track.url.isEmpty) {
      throw Exception('This track does not include a playable preview.');
    }

    if (queue != null && queue.isNotEmpty) {
      final playableQueue = List<Track>.from(
        queue.where((item) => item.url.isNotEmpty),
      );
      _queue
        ..clear()
        ..addAll(playableQueue);
    } else if (!_queue.any((item) => item.id == track.id)) {
      _queue.add(track);
    }

    _currentIndex = _queue.indexWhere((item) => item.id == track.id);
    if (_currentIndex == -1) {
      _queue.add(track);
      _currentIndex = _queue.length - 1;
    }

    _currentTrack = track;
    _addRecentlyPlayed(track);
    final playbackUrl = await _resolvePlaybackUrl(track);
    await _audioPlayer.setUrl(playbackUrl);
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    final nextIndex = _shuffle
        ? DateTime.now().millisecondsSinceEpoch % _queue.length
        : (_currentIndex + 1) % _queue.length;
    await playTrack(_queue[nextIndex], queue: _queue);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final previousIndex =
        _currentIndex <= 0 ? _queue.length - 1 : _currentIndex - 1;
    await playTrack(_queue[previousIndex], queue: _queue);
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> setVolume(double value) async {
    await _audioPlayer.setVolume(value.clamp(0, 1));
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    _loopMode = _loopMode == LoopMode.off ? LoopMode.one : LoopMode.off;
    await _audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  bool isFavorite(Track track) => _favorites.any((item) => item.id == track.id);

  Future<void> toggleFavorite(Track track) async {
    final index = _favorites.indexWhere((item) => item.id == track.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(track);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayed.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentlyPlayed');
    notifyListeners();
  }

  void _addRecentlyPlayed(Track track) {
    _recentlyPlayed.removeWhere((item) => item.id == track.id);
    _recentlyPlayed.insert(0, track);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed.removeRange(20, _recentlyPlayed.length);
    }
    _saveRecentlyPlayed();
  }

  Future<String> _resolvePlaybackUrl(Track track) async {
    if (track.source != 'audius') return track.url;

    try {
      final response = await _dio.get(
        track.url,
        queryParameters: {'no_redirect': true},
      );
      final data = response.data;
      if (data is Map && data['data'] is String) {
        return data['data'] as String;
      }
    } catch (_) {
      // Some platforms handle the normal Audius redirect directly.
    }

    return track.url;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFavorites = prefs.getStringList('favorites') ?? [];
    final rawRecent = prefs.getStringList('recentlyPlayed') ?? [];
    _favorites
      ..clear()
      ..addAll(rawFavorites.map((item) => Track.fromJson(jsonDecode(item))));
    _recentlyPlayed
      ..clear()
      ..addAll(rawRecent.map((item) => Track.fromJson(jsonDecode(item))));
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      _favorites.map((track) => jsonEncode(track.toJson())).toList(),
    );
  }

  Future<void> _saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'recentlyPlayed',
      _recentlyPlayed.map((track) => jsonEncode(track.toJson())).toList(),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
