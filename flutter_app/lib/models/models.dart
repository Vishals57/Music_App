class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String thumbnail;
  final String url;
  final int duration;
  final String source;
  final DateTime? releaseDate;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnail,
    required this.url,
    required this.duration,
    required this.source,
    this.releaseDate,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'] ?? 'Unknown Album',
      thumbnail: json['thumbnail'] ?? '',
      url: json['url'] ?? '',
      duration: json['duration'] ?? 0,
      source: json['source'] ?? 'youtube',
      releaseDate: json['releaseDate'] != null 
        ? DateTime.parse(json['releaseDate'])
        : null,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;
  final String? thumbnail;
  final bool isPublic;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    this.thumbnail,
    required this.isPublic,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id'],
      name: json['name'],
      description: json['description'] ?? '',
      tracks: (json['tracks'] as List)
          .map((t) => Track.fromJson(t))
          .toList(),
      thumbnail: json['thumbnail'],
      isPublic: json['isPublic'] ?? false,
    );
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final List<String> favorites;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.favorites,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      profileImage: json['profileImage'],
      favorites: List<String>.from(json['favorites'] ?? []),
    );
  }
}
