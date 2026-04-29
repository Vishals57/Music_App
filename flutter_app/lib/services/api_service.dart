import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  final Dio _audiusDio = Dio(
    BaseOptions(
      baseUrl: audiusUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  final Dio _deezerDio = Dio(
    BaseOptions(
      baseUrl: deezerUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  final Dio _itunesDio = Dio(
    BaseOptions(
      baseUrl: iTunesUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  static const String audiusUrl = 'https://api.audius.co/v1';
  static const String deezerUrl = 'https://api.deezer.com';
  static const String iTunesUrl = 'https://itunes.apple.com';
  static bool useSampleData = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Auth endpoints
  Future<Response> register(String username, String email, String password) {
    return _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<Response> login(String email, String password) {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  // Music endpoints - combines free APIs:
  // Deezer/iTunes for mainstream previews, Audius for full open streams.
  Future<Response> searchMusic(String query, {String? source}) async {
    final localResults = _filterCatalog(query);

    if (useSampleData) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'results': localResults, 'total': localResults.length},
      );
    }

    try {
      final results = await _searchAllSources(query, limit: 25);
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'results': results, 'total': results.length},
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'results': localResults, 'total': localResults.length},
      );
    }
  }

  // Recent Audius search results, with local full-length tracks as fallback.
  Future<Response> getNewReleases() async {
    if (useSampleData) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: _catalog.take(8).toList(),
      );
    }

    try {
      final year = DateTime.now().year;
      final tracks = await _searchManySources(
        [
          'hindi new songs $year',
          'bollywood new songs $year',
          'marathi new songs $year',
          'india top songs $year',
          'global hits $year',
        ],
        sortMethod: 'recent',
        limit: 12,
      );
      if (tracks.isNotEmpty) {
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: tracks,
        );
      }
    } catch (_) {}

    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: _catalog.take(8).toList(),
    );
  }

  Future<Response> getHindiTracks() async {
    if (useSampleData) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: _catalog.reversed.toList(),
      );
    }

    try {
      final year = DateTime.now().year;
      final tracks = await _searchManySources(
        const [
          'hindi new songs',
          'bollywood latest',
          'marathi new songs',
          'marathi songs',
          'punjabi latest',
          'arijit singh',
          'ajay atul',
          'shreya ghoshal marathi',
          'lofi bollywood',
        ].map((query) => '$query $year').toList(),
        limit: 12,
      );
      if (tracks.isNotEmpty) {
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: tracks,
        );
      }
    } catch (_) {}

    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: _catalog.reversed.toList(),
    );
  }

  // Get trending tracks
  Future<Response> getTrending() async {
    if (useSampleData) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: _catalog.reversed.toList(),
      );
    }

    try {
      final response = await _audiusDio.get(
        '/tracks/trending',
        queryParameters: {
          'limit': 40,
          'time': 'week',
        },
      );
      final tracks = _mapAudiusTracks(response.data['data']);
      if (tracks.isNotEmpty) {
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: tracks,
        );
      }
    } catch (_) {}

    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: _catalog.reversed.toList(),
    );
  }

  Future<Response> getTrack(String id) {
    return _dio.get('/music/$id');
  }

  Future<Response> addToFavorites(String trackId) {
    return _dio.post('/music/$trackId/favorite');
  }

  // Playlist endpoints
  Future<Response> createPlaylist(String name, String description) {
    return _dio.post('/playlist', data: {
      'name': name,
      'description': description,
    });
  }

  Future<Response> getUserPlaylists() {
    return _dio.get('/playlist');
  }

  Future<Response> addTrackToPlaylist(String playlistId, String trackId) {
    return _dio.post('/playlist/$playlistId/add-track', data: {
      'trackId': trackId,
    });
  }

  // User endpoints
  Future<Response> getUserProfile() {
    return _dio.get('/user/profile');
  }

  Future<Response> updateProfile(String username, {String? profileImage}) {
    return _dio.put('/user/profile', data: {
      'username': username,
      if (profileImage != null) 'profileImage': profileImage,
    });
  }

  List<Map<String, dynamic>> _filterCatalog(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _catalog;

    return _catalog.where((track) {
      final searchable =
          '${track['title']} ${track['artist']} ${track['album']}'
              .toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }

  List<Map<String, dynamic>> _mapAudiusTracks(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .where((track) {
          final streamable = track['is_streamable'] ?? track['isStreamable'];
          return streamable == null ||
              streamable == true ||
              streamable == 'true';
        })
        .map((track) {
          final id = (track['id'] ?? '').toString();
          final artwork = _audiusArtwork(track['artwork']);
          final user = track['user'];
          final artist = user is Map<String, dynamic>
              ? (user['name'] ?? user['handle'] ?? 'Audius Artist').toString()
              : 'Audius Artist';

          return {
            'id': id,
            'title': (track['title'] ?? 'Untitled Track').toString(),
            'artist': artist,
            'album': (track['genre'] ?? track['mood'] ?? 'Audius').toString(),
            'duration': ((track['duration'] ?? 0) as num).toInt() * 1000,
            'artwork': artwork,
            'previewUrl': '$audiusUrl/tracks/$id/stream',
            'source': 'audius',
            'releaseDate': track['release_date'] ?? track['releaseDate'],
          };
        })
        .where((track) => (track['id'] as String).isNotEmpty)
        .toList();
  }

  String _audiusArtwork(dynamic artwork) {
    if (artwork is! Map) return '';
    return (artwork['1000x1000'] ??
            artwork['_1000x1000'] ??
            artwork['480x480'] ??
            artwork['_480x480'] ??
            artwork['150x150'] ??
            artwork['_150x150'] ??
            '')
        .toString();
  }

  Future<List<Map<String, dynamic>>> _searchAllSources(
    String query, {
    int limit = 20,
    String sortMethod = 'popular',
  }) async {
    final results = <Map<String, dynamic>>[];

    final searches = await Future.wait<List<Map<String, dynamic>>>(
      [
        _searchDeezerTracks(query, limit: limit),
        _searchITunesTracks(query, limit: limit),
        _searchAudiusTracks(query, sortMethod: sortMethod, limit: limit),
      ],
      eagerError: false,
    );

    for (final tracks in searches) {
      results.addAll(tracks);
    }

    return _dedupeTracks(results);
  }

  Future<List<Map<String, dynamic>>> _searchManySources(
    List<String> queries, {
    String sortMethod = 'popular',
    int limit = 10,
  }) async {
    final allTracks = <Map<String, dynamic>>[];

    for (final query in queries) {
      allTracks.addAll(
        await _searchAllSources(
          query,
          sortMethod: sortMethod,
          limit: limit,
        ),
      );
    }

    return _dedupeTracks(allTracks);
  }

  Future<List<Map<String, dynamic>>> _searchDeezerTracks(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _deezerDio.get(
        '/search/track',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
      );
      return _mapDeezerTracks(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchITunesTracks(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _itunesDio.get(
        '/search',
        queryParameters: {
          'term': query,
          'media': 'music',
          'entity': 'song',
          'country': 'IN',
          'limit': limit,
        },
      );
      return _mapITunesTracks(response.data['results']);
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _mapDeezerTracks(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((track) {
          final artist = track['artist'];
          final album = track['album'];

          return {
            'id': 'deezer-${track['id']}',
            'title': (track['title'] ?? track['title_short'] ?? 'Unknown')
                .toString(),
            'artist': artist is Map
                ? (artist['name'] ?? 'Deezer Artist').toString()
                : 'Deezer Artist',
            'album': album is Map
                ? (album['title'] ?? 'Deezer').toString()
                : 'Deezer',
            'duration': ((track['duration'] ?? 0) as num).toInt() * 1000,
            'artwork': album is Map
                ? (album['cover_xl'] ??
                        album['cover_big'] ??
                        album['cover_medium'] ??
                        album['cover'] ??
                        '')
                    .toString()
                : '',
            'previewUrl': (track['preview'] ?? '').toString(),
            'source': 'deezer',
          };
        })
        .where((track) => (track['previewUrl'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _mapITunesTracks(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((track) {
          return {
            'id': 'itunes-${track['trackId']}',
            'title': (track['trackName'] ?? 'Unknown').toString(),
            'artist': (track['artistName'] ?? 'iTunes Artist').toString(),
            'album': (track['collectionName'] ?? 'iTunes').toString(),
            'duration': ((track['trackTimeMillis'] ?? 0) as num).toInt(),
            'artwork': (track['artworkUrl100'] ?? '')
                .toString()
                .replaceAll('100x100', '600x600'),
            'previewUrl': (track['previewUrl'] ?? '').toString(),
            'source': 'itunes',
            'releaseDate': track['releaseDate'],
          };
        })
        .where((track) => (track['previewUrl'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _dedupeTracks(List<Map<String, dynamic>> tracks) {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];

    for (final track in tracks) {
      final key = '${track['title']}-${track['artist']}'
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      if (seen.add(key)) {
        deduped.add(track);
      }
    }

    return deduped;
  }

  Future<List<Map<String, dynamic>>> _searchAudiusTracks(
    String query, {
    String sortMethod = 'popular',
    int limit = 20,
  }) async {
    final response = await _audiusDio.get(
      '/tracks/search',
      queryParameters: {
        'query': query,
        'limit': limit,
        'sort_method': sortMethod,
        'includePurchaseable': false,
      },
    );
    return _mapAudiusTracks(response.data['data']);
  }

  List<Map<String, dynamic>> get _catalog => const [
        {
          'id': 'sample-1',
          'title': 'SoundHelix Song 1',
          'artist': 'SoundHelix',
          'album': 'Open Instrumentals',
          'duration': 372000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-2',
          'title': 'SoundHelix Song 2',
          'artist': 'SoundHelix',
          'album': 'Open Instrumentals',
          'duration': 310000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-3',
          'title': 'SoundHelix Song 3',
          'artist': 'SoundHelix',
          'album': 'Open Instrumentals',
          'duration': 345000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-4',
          'title': 'SoundHelix Song 4',
          'artist': 'SoundHelix',
          'album': 'Free Streaming Set',
          'duration': 305000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-5',
          'title': 'SoundHelix Song 5',
          'artist': 'SoundHelix',
          'album': 'Free Streaming Set',
          'duration': 287000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-6',
          'title': 'SoundHelix Song 6',
          'artist': 'SoundHelix',
          'album': 'Free Streaming Set',
          'duration': 322000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-7',
          'title': 'SoundHelix Song 7',
          'artist': 'SoundHelix',
          'album': 'No Cost Radio',
          'duration': 293000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-8',
          'title': 'SoundHelix Song 8',
          'artist': 'SoundHelix',
          'album': 'No Cost Radio',
          'duration': 333000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-9',
          'title': 'SoundHelix Song 9',
          'artist': 'SoundHelix',
          'album': 'Open Instrumentals',
          'duration': 302000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
          'source': 'soundhelix',
        },
        {
          'id': 'sample-10',
          'title': 'SoundHelix Song 10',
          'artist': 'SoundHelix',
          'album': 'No Cost Radio',
          'duration': 299000,
          'artwork': '',
          'previewUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
          'source': 'soundhelix',
        },
      ];
}
