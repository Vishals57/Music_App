import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  // Use iTunes API for search (free, no API key needed)
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  static const String iTunesUrl = 'https://itunes.apple.com';
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setToken(String token) {
    _token = token;
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

  // Music endpoints - using iTunes API for search
  Future<Response> searchMusic(String query, {String? source}) async {
    try {
      // Try iTunes API first (free, no key required)
      final response = await Dio().get(
        '$iTunesUrl/search',
        queryParameters: {
          'term': query,
          'media': 'music',
          'entity': 'song',
          'limit': 25,
        },
      );
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'results': (response.data['results'] as List).map((track) => {
            'id': track['trackId']?.toString() ?? '',
            'title': track['trackName'] ?? '',
            'artist': track['artistName'] ?? '',
            'album': track['collectionName'] ?? '',
            'duration': track['trackTimeMillis'] ?? 0,
            'artwork': track['artworkUrl100']?.replaceAll('100x100', '300x300') ?? '',
            'previewUrl': track['previewUrl'] ?? '',
            'source': 'itunes',
          }).toList(),
          'total': response.data['resultCount'] ?? 0,
        },
      );
    } catch (e) {
      // Fallback to backend
      return _dio.get('/music/search', queryParameters: {
        'query': query,
        if (source != null) 'source': source,
      });
    }
  }

  // Get sample tracks for new releases (using iTunes)
  Future<Response> getNewReleases() async {
    try {
      final response = await Dio().get(
        '$iTunesUrl/search',
        queryParameters: {
          'term': 'popular music',
          'media': 'music',
          'entity': 'song',
          'limit': 20,
        },
      );
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: (response.data['results'] as List).map((track) => {
          'id': track['trackId']?.toString() ?? '',
          'title': track['trackName'] ?? '',
          'artist': track['artistName'] ?? '',
          'album': track['collectionName'] ?? '',
          'duration': track['trackTimeMillis'] ?? 0,
          'artwork': track['artworkUrl100']?.replaceAll('100x100', '300x300') ?? '',
          'previewUrl': track['previewUrl'] ?? '',
          'source': 'itunes',
        }).toList(),
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        data: [],
      );
    }
  }

  // Get trending tracks
  Future<Response> getTrending() async {
    try {
      final response = await Dio().get(
        '$iTunesUrl/search',
        queryParameters: {
          'term': 'top hits',
          'media': 'music',
          'entity': 'song',
          'limit': 20,
        },
      );
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: (response.data['results'] as List).map((track) => {
          'id': track['trackId']?.toString() ?? '',
          'title': track['trackName'] ?? '',
          'artist': track['artistName'] ?? '',
          'album': track['collectionName'] ?? '',
          'duration': track['trackTimeMillis'] ?? 0,
          'artwork': track['artworkUrl100']?.replaceAll('100x100', '300x300') ?? '',
          'previewUrl': track['previewUrl'] ?? '',
          'source': 'itunes',
        }).toList(),
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        data: [],
      );
    }
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
}
