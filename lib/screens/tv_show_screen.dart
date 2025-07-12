import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:semo/components/episode_card.dart';
import 'package:semo/components/horizontal_media_list.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/components/media_info.dart';
import 'package:semo/components/media_poster.dart';
import 'package:semo/components/person_card.dart';
import 'package:semo/components/season_selector.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/screens/person_media_screen.dart';
import 'package:semo/screens/player_screen.dart';
import 'package:semo/screens/view_all_screen.dart';
import 'package:semo/services/favorites_service.dart';
import 'package:semo/services/recently_watched_service.dart';
import 'package:semo/services/subtitle_service.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/enums/media_type.dart';
import 'package:semo/utils/extractor.dart';
import 'package:semo/utils/navigation_helper.dart';
import 'package:semo/components/spinner.dart';
import 'package:semo/utils/urls.dart';

class TvShowScreen extends StatefulWidget {
  final TvShow tvShow;

  const TvShowScreen(this.tvShow, {Key? key}) : super(key: key);

  @override
  _TvShowScreenState createState() => _TvShowScreenState();
}

class _TvShowScreenState extends State<TvShowScreen> {
  late TvShow _tvShow;
  late Spinner _spinner;
  final TMDBService _tmdbService = TMDBService();
  final FavoritesService _favoritesService = FavoritesService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  final SubtitleService _subtitleService = SubtitleService();
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isConnectedToInternet = true;
  int _currentSeasonIndex = 0;

  // Pagination controllers using v5.x API
  late final PagingController<int, TvShow> _recommendationsController = PagingController<int, TvShow>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getRecommendations(
        MediaType.tvShows,
        _tvShow.id,
        pageKey,
      );
      return result.tvShows ?? [];
    },
  );

  late final PagingController<int, TvShow> _similarController = PagingController<int, TvShow>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getSimilar(
        MediaType.tvShows,
        _tvShow.id,
        pageKey,
      );
      return result.tvShows ?? [];
    },
  );

  late StreamSubscription _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _tvShow = widget.tvShow;
    _initializeScreen();
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _recommendationsController.dispose();
    _similarController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  Future<void> _initializeScreen() async {
    await _initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'TV Show - ${_tvShow.name}',
      );
      await _loadTvShowDetails();
    });
  }

  Future<void> _initConnectivity() async {
    _isConnectedToInternet = await InternetConnection().hasInternetAccess;
    _connectionSubscription =
        InternetConnection().onStatusChange.listen((status) {
          if (mounted) {
            setState(() {
              _isConnectedToInternet = status == InternetStatus.connected;
            });
          }
        });
  }

  Future<void> _loadTvShowDetails() async {
    if (!_isConnectedToInternet) return;

    _spinner.show();
    try {
      await Future.wait([
        _checkIfFavorite(),
        _loadSeasons(),
        _loadTrailer(),
        _loadCast(),
      ]);
    } catch (_) {
      _showErrorSnackBar('Failed to load TV show details');
    } finally {
      _spinner.dismiss();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfFavorite() async {
    final favs = await _favoritesService.getFavoriteTvShows();
    if (mounted) {
      setState(() => _isFavorite = favs.contains(_tvShow.id));
    }
  }

  Future<void> _loadSeasons() async {
    final seasons = await _tmdbService.getTvShowSeasons(_tvShow.id);
    if (mounted && seasons.isNotEmpty) {
      setState(() => _tvShow.seasons = seasons);
      await _loadEpisodesForSeason(0);
    }
  }

  Future<void> _loadEpisodesForSeason(int seasonIndex) async {
    if (_tvShow.seasons == null || seasonIndex >= _tvShow.seasons!.length) return;
    final season = _tvShow.seasons![seasonIndex];
    if (season.episodes != null) return;

    _spinner.show();
    try {
      final episodes = await _tmdbService.getEpisodes(
        _tvShow.id,
        season.number,
        _tvShow.name,
      );
      final recentlyWatched = await _recentlyWatchedService.getEpisodes(
        _tvShow.id,
        season.id,
      );
      if (recentlyWatched != null) {
        for (final ep in episodes) {
          final data = recentlyWatched['${ep.id}'];
          if (data != null) {
            ep.isRecentlyWatched = true;
            ep.watchedProgress = data['progress'] ?? 0;
          }
        }
      }
      if (mounted) {
        setState(() => _tvShow.seasons![seasonIndex].episodes = episodes);
      }
    } catch (_) {
      _showErrorSnackBar('Failed to load episodes');
    } finally {
      _spinner.dismiss();
    }
  }

  Future<void> _loadTrailer() async {
    final url = await _tmdbService.getTrailerUrl(MediaType.tvShows, _tvShow.id);
    if (mounted && url != null) {
      setState(() => _tvShow.trailerUrl = url);
    }
  }

  Future<void> _loadCast() async {
    final cast = await _tmdbService.getCast(MediaType.tvShows, _tvShow.id);
    if (mounted) {
      setState(() => _tvShow.cast = cast);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _favoritesService.removeTvShowFromFavorites(_tvShow.id);
      } else {
        await _favoritesService.addTvShowToFavorites(_tvShow.id);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {
      _showErrorSnackBar('Failed to update favorites');
    }
  }

  Future<void> _playEpisode(Episode episode) async {
    final season = _tvShow.seasons![_currentSeasonIndex];
    _spinner.show();
    try {
      final extractor = Extractor(episode: episode);
      final stream = await extractor.getStream();
      final subs = await _subtitleService.getTvShowSubtitles(
        _tvShow.id,
        episode.season,
        episode.number,
      );
      _spinner.dismiss();

      if (stream.url != null) {
        final result = await NavigationHelper.navigate(
          context,
          PlayerScreen(
            id: _tvShow.id,
            seasonId: season.id,
            episodeId: episode.id,
            title: episode.name,
            stream: stream,
            subtitles: subs,
            mediaType: MediaType.tvShows,
          ),
        );
        if (result != null) _handlePlayerResult(result);
      } else {
        _showErrorSnackBar('No stream link found');
      }
    } catch (_) {
      _spinner.dismiss();
      _showErrorSnackBar('Failed to load stream');
    }
  }

  void _handlePlayerResult(Map<String, dynamic> result) {
    final epId = result['episodeId'] as int?;
    final prog = result['progress'] as int?;
    if (epId != null && prog != null) {
      final episodes = _tvShow.seasons![_currentSeasonIndex].episodes!;
      final idx = episodes.indexWhere((e) => e.id == epId);
      if (idx != -1) {
        setState(() {
          episodes[idx].isRecentlyWatched = true;
          episodes[idx].watchedProgress = prog;
        });
      }
    }
  }

  Future<void> _markEpisodeAsWatched(Episode episode) async {
    final season = _tvShow.seasons![_currentSeasonIndex];
    try {
      await _recentlyWatchedService.updateEpisodeProgress(
        _tvShow.id,
        season.id,
        episode.id,
        episode.duration * 60,
      );
      setState(() {
        episode.isRecentlyWatched = true;
        episode.watchedProgress = episode.duration * 60;
      });
    } catch (_) {
      _showErrorSnackBar('Failed to mark episode as watched');
    }
  }

  Future<void> _removeEpisodeFromWatched(Episode episode) async {
    final season = _tvShow.seasons![_currentSeasonIndex];
    try {
      await _recentlyWatchedService.removeEpisodeProgress(
        _tvShow.id,
        season.id,
        episode.id,
      );
      setState(() {
        episode.isRecentlyWatched = false;
        episode.watchedProgress = null;
      });
    } catch (_) {
      _showErrorSnackBar('Failed to remove episode from watched');
    }
  }

  Future<void> _onSeasonChanged(Season season) async {
    final newIndex = _tvShow.seasons!.indexOf(season);
    if (newIndex != -1) {
      setState(() => _currentSeasonIndex = newIndex);
      if (season.episodes == null) {
        await _loadEpisodesForSeason(newIndex);
      }
    }
  }

  Future<void> _refreshData() async {
    _recommendationsController.refresh();
    _similarController.refresh();
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      _tvShow.trailerUrl = null;
      _tvShow.cast = null;
      _tvShow.seasons = null;
      _currentSeasonIndex = 0;
    });
    await _loadTvShowDetails();
  }

  Widget _buildSeasonsSection() {
    if (_tvShow.seasons == null || _tvShow.seasons!.isEmpty) {
      return const SizedBox.shrink();
    }
    final currentSeason = _tvShow.seasons![_currentSeasonIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SeasonSelector(
              seasons: _tvShow.seasons!,
              selectedSeason: currentSeason,
              onSeasonChanged: _onSeasonChanged,
            ),
            const Spacer(),
          ],
        ),
        if (currentSeason.episodes != null)
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: currentSeason.episodes!.length,
            itemBuilder: (ctx, i) {
              final eps = currentSeason.episodes![i];
              return EpisodeCard(
                episode: eps,
                onTap: () => _playEpisode(eps),
                onMarkWatched: () => _markEpisodeAsWatched(eps),
                onRemove: eps.isRecentlyWatched
                    ? () => _removeEpisodeFromWatched(eps)
                    : null,
              );
            },
          ),
      ],
    );
  }

  Widget _buildCastSection() {
    if (_tvShow.cast == null || _tvShow.cast!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cast', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _tvShow.cast!.length,
            itemBuilder: (ctx, i) => Padding(
              padding: EdgeInsets.only(
                  right: i < _tvShow.cast!.length - 1 ? 18 : 0),
              child: PersonCard(
                person: _tvShow.cast![i],
                onTap: () => NavigationHelper.navigate(
                  context,
                  PersonMediaScreen(_tvShow.cast![i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_off_sharp, size: 80, color: Colors.white54),
          SizedBox(height: 10),
          Text(
            'You have lost internet connection',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context, 'refresh')),
        actions: [
          if (_isConnectedToInternet)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              color: _isFavorite ? Colors.red : Colors.white,
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: SafeArea(
        child: _isConnectedToInternet ? RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: !_isLoading ? SingleChildScrollView(
            child: Column(
              children: [
                MediaPoster(
                  backdropPath: _tvShow.backdropPath,
                  trailerUrl: _tvShow.trailerUrl,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaInfo(
                        title: _tvShow.name,
                        subtitle: _tvShow.firstAirDate.split('-')[0],
                        overview: _tvShow.overview,
                      ),
                      const SizedBox(height: 30),
                      _buildSeasonsSection(),
                      const SizedBox(height: 30),
                      _buildCastSection(),
                      const SizedBox(height: 30),
                      HorizontalMediaList<TvShow>(
                        title: 'Recommendations',
                        source: Urls.getTvShowRecommendations(_tvShow.id),
                        pagingController: _recommendationsController,
                        itemBuilder: (c, show, i) => Padding(
                          padding: EdgeInsets.only(
                            right: i < (_recommendationsController.items?.length ?? 0) - 1 ? 18 : 0,
                          ),
                          child: MediaCard(
                            posterPath: show.posterPath,
                            title: show.name,
                            year: show.firstAirDate.split('-')[0],
                            voteAverage: show.voteAverage,
                            onTap: () => NavigationHelper.navigate(
                              context,
                              TvShowScreen(show),
                            ),
                          ),
                        ),
                        onViewAllTap: () => NavigationHelper.navigate(
                          context,
                          ViewAllScreen(
                            title: 'Recommendations',
                            source: Urls.getTvShowRecommendations(_tvShow.id),
                            mediaType: MediaType.tvShows,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      HorizontalMediaList<TvShow>(
                        title: 'Similar',
                        source: Urls.getTvShowSimilar(_tvShow.id),
                        pagingController: _similarController,
                        itemBuilder: (c, show, i) => Padding(
                          padding: EdgeInsets.only(
                            right: i < (_similarController.items?.length ?? 0) - 1 ? 18 : 0,
                          ),
                          child: MediaCard(
                            posterPath: show.posterPath,
                            title: show.name,
                            year: show.firstAirDate.split('-')[0],
                            voteAverage: show.voteAverage,
                            onTap: () => NavigationHelper.navigate(
                              context,
                              TvShowScreen(show),
                            ),
                          ),
                        ),
                        onViewAllTap: () => NavigationHelper.navigate(
                          context,
                          ViewAllScreen(
                            title: 'Similar',
                            source: Urls.getTvShowSimilar(_tvShow.id),
                            mediaType: MediaType.tvShows,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ) : const Center(child: CircularProgressIndicator()),
        ) : _buildNoInternet(),
      ),
    );
  }
}
