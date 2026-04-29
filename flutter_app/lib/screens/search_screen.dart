import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../screens/now_playing_screen.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Track> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await _apiService.searchMusic(query);
      setState(() {
        final results = response.data['results'] as List<dynamic>? ?? [];
        _searchResults = results
            .whereType<Map<String, dynamic>>()
            .map(Track.fromJson)
            .where((track) => track.url.isNotEmpty)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              onSubmitted: _search,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _QuickSearchChip(label: 'Hindi', onTap: _searchWithChip),
                _QuickSearchChip(label: 'Bollywood', onTap: _searchWithChip),
                _QuickSearchChip(label: 'Marathi', onTap: _searchWithChip),
                _QuickSearchChip(
                    label: 'Marathi New Songs', onTap: _searchWithChip),
                _QuickSearchChip(label: 'Punjabi', onTap: _searchWithChip),
                _QuickSearchChip(label: 'Arijit Singh', onTap: _searchWithChip),
                _QuickSearchChip(label: 'Ajay Atul', onTap: _searchWithChip),
                _QuickSearchChip(
                    label: 'Lofi Bollywood', onTap: _searchWithChip),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Search for your favorite music',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final track = _searchResults[index];
                              return _buildTrackTile(track);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _searchWithChip(String query) {
    _searchController.text = query;
    _search(query);
  }

  Future<void> _play(Track track) async {
    try {
      await context
          .read<PlayerService>()
          .playTrack(track, queue: _searchResults);
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

  Widget _buildTrackTile(Track track) {
    final player = context.watch<PlayerService>();
    final isFavorite = player.isFavorite(track);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: track.thumbnail.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(track.thumbnail),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
          child: track.thumbnail.isEmpty
              ? const Icon(Icons.music_note, color: AppTheme.primaryColor)
              : null,
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color:
                    isFavorite ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              onPressed: () => player.toggleFavorite(track),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_fill,
                  color: AppTheme.primaryColor, size: 36),
              onPressed: () => _play(track),
            ),
          ],
        ),
        onTap: () => _play(track),
      ),
    );
  }
}

class _QuickSearchChip extends StatelessWidget {
  final String label;
  final ValueChanged<String> onTap;

  const _QuickSearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.music_note, size: 18),
        onPressed: () => onTap(label),
      ),
    );
  }
}
