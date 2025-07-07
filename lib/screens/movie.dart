import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:semo/components/horizontal_media_list.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/components/media_info.dart';
import 'package:semo/components/media_poster.dart';
import 'package:semo/components/person_card.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/screens/person_media.dart';
import 'package:semo/screens/player.dart';
import 'package:semo/screens/view_all.dart';
import 'package:semo/services/favorites_service.dart';
import 'package:semo/services/recently_watched_service.dart';
import 'package:semo/services/subtitle_service.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/extractor.dart';
import 'package:semo/utils/navigation_helper.dart';
import 'package:semo/components/spinner.dart';
import 'package:semo/utils/urls.dart';

class Movie extends StatefulWidget {
  final model.Movie movie;

  const Movie(this.movie, {Key? key}) : super(key: key);

  @override
  _MovieState createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  late model.Movie _movie;
  late Spinner _spinner;

  // Services
  final TMDBService _tmdbService = TMDBService();
  final FavoritesService _favoritesService = FavoritesService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  final SubtitleService _subtitleService = SubtitleService();

  // State flags
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isConnectedToInternet = true;

  // Pagination controllers using v5.x API
  late final PagingController<int, model.Movie> _recommendationsController = PagingController<int, model.Movie>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getRecommendations(
        _movie.id,
        pageKey,
        PageType.movies,
      );
      return result.movies ?? [];
    },
  );

  late final PagingController<int, model.Movie> _similarController = PagingController<int, model.Movie>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getSimilar(
        _movie.id,
        pageKey,
        PageType.movies,
      );
      return result.movies ?? [];
    },
  );

  // Connectivity subscription
  late StreamSubscription _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _initializeScreen();
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _recommendationsController.dispose();
    _similarController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _initConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Movie - ${_movie.title}',
      );
      await _loadMovieDetails();
    });
  }

  Future<void> _initConnectivity() async {
    _isConnectedToInternet = await InternetConnection().hasInternetAccess;
    _connectionSubscription =
        InternetConnection().onStatusChange.listen((status) {
          if (mounted) {
            setState(() {
              _isConnectedToInternet =
                  status == InternetStatus.connected;
            });
          }
        });
  }

  Future<void> _loadMovieDetails() async {
    if (!_isConnectedToInternet) return;

    _spinner.show();
    try {
      await Future.wait([
        _checkIfFavorite(),
        _checkRecentlyWatched(),
        _loadTrailer(),
        _loadDuration(),
        _loadCast(),
      ]);
    } catch (_) {
      _showErrorSnackBar('Failed to load movie details');
    } finally {
      _spinner.dismiss();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfFavorite() async {
    final favs = await _favoritesService.getFavoriteMovies();
    if (mounted) {
      setState(() => _isFavorite = favs.contains(_movie.id));
    }
  }

  Future<void> _checkRecentlyWatched() async {
    final prog = await _recentlyWatchedService.getMovieProgress(_movie.id);
    if (mounted && prog != null) {
      setState(() {
        _movie.isRecentlyWatched = true;
        _movie.watchedProgress = prog;
      });
    }
  }

  Future<void> _loadTrailer() async {
    final url = await _tmdbService.getTrailerUrl(_movie.id);
    if (mounted && url != null) {
      setState(() => _movie.trailerUrl = url);
    }
  }

  Future<void> _loadDuration() async {
    final d = await _tmdbService.getMovieDuration(_movie.id);
    if (mounted && d != null) {
      setState(() => _movie.duration = d);
    }
  }

  Future<void> _loadCast() async {
    final cast = await _tmdbService.getCast(_movie.id);
    if (mounted) {
      setState(() => _movie.cast = cast);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _favoritesService.removeMovieFromFavorites(_movie.id);
      } else {
        await _favoritesService.addMovieToFavorites(_movie.id);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {
      _showErrorSnackBar('Failed to update favorites');
    }
  }

  Future<void> _playMovie() async {
    _spinner.show();
    try {
      final extractor = Extractor(movie: _movie);
      final stream = await extractor.getStream();
      final subs = await _subtitleService.getMovieSubtitles(_movie.id);
      _spinner.dismiss();

      if (stream.url != null) {
        final result = await NavigationHelper.navigate(
          context,
          Player(
            id: _movie.id,
            title: _movie.title,
            stream: stream,
            subtitles: subs,
            pageType: PageType.movies,
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
    if (result['error'] != null) {
      _showErrorSnackBar('Playback error. Try again');
    } else if (result['progress'] != null) {
      setState(() {
        _movie.isRecentlyWatched = true;
        _movie.watchedProgress = result['progress'];
      });
    }
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

  Future<void> _refreshData() async {
    _recommendationsController.refresh();
    _similarController.refresh();
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      _movie.trailerUrl = null;
      _movie.cast = null;
    });
    await _loadMovieDetails();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '\$h ${h == 1 ? 'hr' : 'hrs'}${m > 0 ? ' \$m ${m == 1 ? 'min' : 'mins'}' : ''}';
    }
    return '\$m ${m == 1 ? 'min' : 'mins'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
        BackButton(onPressed: () => Navigator.pop(context, 'refresh')),
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
          backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
          child: !_isLoading ? SingleChildScrollView(
            child: Column(
              children: [
                MediaPoster(
                  backdropPath: _movie.backdropPath,
                  trailerUrl: _movie.trailerUrl,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      MediaInfo(
                        title: _movie.title,
                        subtitle: _movie.duration != null
                            ? '${_movie.releaseDate.split('-')[0]} · ${_formatDuration(Duration(minutes: _movie.duration!))}'
                            : _movie.releaseDate.split('-')[0],
                        overview: _movie.overview,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _playMovie,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.play_arrow,
                                size: 25,
                              ),
                              SizedBox(width: 5),
                              Text('Play'),
                            ],
                          ),
                        ),
                      ),
                      if (_movie.cast?.isNotEmpty == true)
                        ...[
                          const SizedBox(height: 30),
                          Text(
                            'Cast',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: ListView.builder(
                              scrollDirection:
                              Axis.horizontal,
                              itemCount: _movie.cast!.length,
                              itemBuilder: (c, i) => Padding(
                                padding:
                                EdgeInsets.only(
                                  right: i < _movie.cast!.length - 1 ? 18 : 0,
                                ),
                                child: PersonCard(
                                  person: _movie.cast![i],
                                  onTap: () => NavigationHelper.navigate(
                                    context,
                                    PersonMedia(_movie.cast![i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      const SizedBox(height: 30),
                      HorizontalMediaList<model.Movie>(
                        title: 'Recommendations',
                        source: Urls.getMovieRecommendations(_movie.id),
                        pagingController:
                        _recommendationsController,
                        itemBuilder: (c, m, i) => Padding(
                          padding: EdgeInsets.only(
                            right: i < (_recommendationsController.items?.length ?? 0) - 1 ? 18 : 0,
                          ),
                          child: MediaCard(
                            posterPath: m.posterPath,
                            title: m.title,
                            year: m.releaseDate.split('-')[0],
                            voteAverage: m.voteAverage,
                            onTap: () => NavigationHelper.navigate(
                              context,
                              Movie(m),
                            ),
                          ),
                        ),
                        onViewAllTap: () =>
                            NavigationHelper.navigate(
                              context,
                              ViewAll(
                                title: 'Recommendations',
                                source: Urls.getMovieRecommendations(_movie.id),
                                pageType: PageType.movies,
                              ),
                            ),
                      ),
                      const SizedBox(height: 30),
                      HorizontalMediaList<model.Movie>(
                        title: 'Similar',
                        source: Urls.getMovieSimilar(_movie.id),
                        pagingController:
                        _similarController,
                        itemBuilder: (c, m, i) => Padding(
                          padding: EdgeInsets.only(
                            right: i < (_similarController.items?.length ?? 0) - 1 ? 18 : 0,
                          ),
                          child: MediaCard(
                            posterPath: m.posterPath,
                            title: m.title,
                            year: m.releaseDate.split('-')[0],
                            voteAverage: m.voteAverage,
                            onTap: () => NavigationHelper.navigate(
                              context,
                              Movie(m),
                            ),
                          ),
                        ),
                        onViewAllTap: () =>
                            NavigationHelper.navigate(
                              context,
                              ViewAll(
                                title: 'Similar',
                                source: Urls.getMovieSimilar(_movie.id),
                                pageType: PageType.movies,
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
}
