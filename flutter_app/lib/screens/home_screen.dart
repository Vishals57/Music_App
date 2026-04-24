import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _newReleases = [];
  List<dynamic> _trending = [];
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
      final trending = await _apiService.getTrending();

      setState(() {
        _newReleases = releases.data as List<dynamic>? ?? [];
        _trending = trending.data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text('Error: $_error',
                            style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppTheme.primaryColor,
                    child: CustomScrollView(
                      slivers: [
                        // App Bar
                        SliverAppBar(
                          backgroundColor: AppTheme.backgroundColor,
                          floating: true,
                          pinned: false,
                          elevation: 0,
                          title: const Text(
                            'Music Player',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.search,
                                  color: AppTheme.primaryColor),
                              onPressed: () {
                                // Navigate to search
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings,
                                  color: AppTheme.primaryColor),
                              onPressed: () {
                                // Navigate to settings
                              },
                            ),
                          ],
                        ),
                        // Content
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // New Releases Section
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'New Releases',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 250,
                                      child: _newReleases.isEmpty
                                          ? const Center(
                                              child: Text('No releases found',
                                                  style: TextStyle(
                                                      color: AppTheme.textSecondary)))
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _newReleases.length,
                                              itemBuilder: (context, index) {
                                                final track = _newReleases[index];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 12),
                                                  child: Container(
                                                    width: 180,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: AppTheme.surfaceColor,
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          height: 150,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .vertical(
                                                              top: Radius.circular(
                                                                  12),
                                                            ),
                                                            image: track['artwork'] !=
                                                                        null &&
                                                                    track['artwork']
                                                                        .isNotEmpty
                                                                ? DecorationImage(
                                                                    image: NetworkImage(
                                                                        track[
                                                                            'artwork']),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : null,
                                                            gradient: track[
                                                                        'artwork'] ==
                                                                    null ||
                                                                track['artwork']
                                                                    .isEmpty
                                                                ? LinearGradient(
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .bottomRight,
                                                                    colors: [
                                                                      AppTheme
                                                                          .primaryColor
                                                                          .withOpacity(
                                                                              0.3),
                                                                      AppTheme
                                                                          .accentColor
                                                                          .withOpacity(
                                                                              0.3),
                                                                    ],
                                                                  )
                                                                : null,
                                                          ),
                                                          child: track['artwork'] ==
                                                                      null ||
                                                                  track['artwork']
                                                                      .isEmpty
                                                              ? const Icon(
                                                                  Icons.music_note,
                                                                  size: 60,
                                                                  color: AppTheme
                                                                      .primaryColor,
                                                                )
                                                              : null,
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  track['title'] ??
                                                                      'Unknown',
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: AppTheme
                                                                        .textPrimary,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  track['artist'] ??
                                                                      'Unknown Artist',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 12,
                                                                    color: AppTheme
                                                                        .textSecondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              // Trending Section
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trending Now',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _trending.isEmpty
                                        ? const Center(
                                            child: Text('No trending tracks',
                                                style: TextStyle(
                                                    color: AppTheme.textSecondary)))
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: 0.9,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                            ),
                                            itemCount: _trending.length > 6
                                                ? 6
                                                : _trending.length,
                                            itemBuilder: (context, index) {
                                              final track = _trending[index];
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: AppTheme.surfaceColor,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      height: 120,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              12),
                                                        ),
                                                        image: track['artwork'] !=
                                                                    null &&
                                                                track['artwork']
                                                                    .isNotEmpty
                                                            ? DecorationImage(
                                                                image: NetworkImage(
                                                                    track[
                                                                        'artwork']),
                                                                fit: BoxFit.cover,
                                                              )
                                                            : null,
                                                        gradient: track[
                                                                    'artwork'] ==
                                                                null ||
                                                            track['artwork']
                                                                .isEmpty
                                                            ? LinearGradient(
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                                colors: [
                                                                  AppTheme
                                                                      .primaryColor
                                                                      .withOpacity(
                                                                          0.4),
                                                                  AppTheme
                                                                      .accentColor
                                                                      .withOpacity(
                                                                          0.2),
                                                                ],
                                                              )
                                                            : null,
                                                      ),
                                                      child: track['artwork'] ==
                                                                  null ||
                                                              track['artwork']
                                                                  .isEmpty
                                                          ? const Icon(
                                                              Icons.album,
                                                              size: 50,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                            )
                                                          : null,
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(10),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              track['title'] ??
                                                                  'Unknown',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                                color: AppTheme
                                                                    .textPrimary,
                                                              ),
                                                            ),
                                                            Text(
                                                              track['artist'] ??
                                                                  'Unknown Artist',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                color: AppTheme
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
