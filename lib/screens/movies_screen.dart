import "dart:async";

import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/carousel_slider.dart";
import "package:semo/components/genres_horizontal_list.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/genre.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/search_results.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/components/streaming_platform_card_horizontal_list.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/urls.dart";

class MoviesScreen extends BaseScreen {
  const MoviesScreen({super.key});

  @override
  BaseScreenState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends BaseScreenState<MoviesScreen> {
  final TMDBService _tmdbService = TMDBService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  bool _isLoading = true;
  List<Movie> _nowPlaying = <Movie>[];
  int _currentNowPlayingIndex = 0;
  List<Movie> _recentlyWatched = <Movie>[];
  List<Genre> _genres = <Genre>[];
  late final PagingController<int, Movie> _trendingController = PagingController<int, Movie>(
    getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getTrendingMovies(pageKey);
      return results.movies ?? <Movie>[];
    },
  );
  late final PagingController<int, Movie> _popularController = PagingController<int, Movie>(
    getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getPopularMovies(pageKey);
      return results.movies ?? <Movie>[];
    },
  );
  late final PagingController<int, Movie> _topRatedController = PagingController<int, Movie>(
    getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getTopRatedMovies(pageKey);
      return results.movies ?? <Movie>[];
    },
  );

  Future<void> _loadAllData() async {
    await Future.wait(<Future<void>>[
      _loadNowPlaying(),
      _loadRecentlyWatched(),
      _loadGenres(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNowPlaying() async {
    try {
      final SearchResults results = await _tmdbService.getNowPlayingMovies();
      final List<Movie> movies = results.movies ?? <Movie>[];
      setState(() => _nowPlaying = movies.length > 10 ? movies.sublist(0, 10) : movies);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load now playing");
      }
    }
  }

  Future<void> _loadRecentlyWatched() async {
    try {
      final List<int> recentlyWatchedIds = await _recentlyWatchedService.getMovieIds();
      final List<Movie> movies = <Movie>[];

      for (final int id in recentlyWatchedIds) {
        final Movie? movie = await _tmdbService.getMovie(id);
        if (movie != null) {
          movies.add(movie);
        }
      }

      setState(() => _recentlyWatched = movies);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load recently watched");
      }
    }
  }

  Future<void> _loadGenres() async {
    try {
      final List<Genre> genres = await _tmdbService.getMovieGenres();
      setState(() => _genres = genres);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load genres");
      }
    }
  }

  void _removeFromRecentlyWatched(Movie movie) {
    List<Movie> recentlyWatched = _recentlyWatched;

    try {
      unawaited(_recentlyWatchedService.removeMovie(movie.id));
    } catch (_) {}

    recentlyWatched.removeWhere((Movie m) => m.id == movie.id);
    setState(() => _recentlyWatched = recentlyWatched);
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _nowPlaying = <Movie>[];
      _recentlyWatched = <Movie>[];
      _genres = <Genre>[];
    });

    _trendingController.refresh();
    _popularController.refresh();
    _topRatedController.refresh();

    await _loadAllData();
  }

  Future<void> _navigateToMovie(Movie movie) async {
    final dynamic result = await navigate(MovieScreen(movie));
    if (result == "refresh") {
      await _loadRecentlyWatched();
    }
  }

  Widget _buildNowPlaying() {
    if (_nowPlaying.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      items: _nowPlaying,
      currentItemIndex: _currentNowPlayingIndex,
      onItemChanged: (int index) => setState(() => _currentNowPlayingIndex = index),
      onItemTap: (int index) => _navigateToMovie(_nowPlaying[index]),
      mediaType: MediaType.movies,
    );
  }

  Widget _buildRecentlyWatched() {
    if (_recentlyWatched.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: HorizontalMediaList<Movie>(
        title: "Recently watched",
        items: _recentlyWatched,
        itemBuilder: (BuildContext context, Movie movie, int index) => Padding(
          padding: EdgeInsets.only(
            right: index < (_recentlyWatched.length) - 1 ? 18 : 0,
          ),
          child: MediaCard(
            media: movie,
            mediaType: MediaType.movies,
            onTap: () => _navigateToMovie(movie),
            showRemoveOption: true,
            onRemove: () => _removeFromRecentlyWatched(movie),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({
    required PagingController<int, Movie> controller,
    required String title,
    required String viewAllSource,
  }) => Padding(
    padding: const EdgeInsets.only(top: 30),
    child: MediaCardHorizontalList(
      title: title,
      pagingController: controller,
      viewAllSource: viewAllSource,
      mediaType: MediaType.movies,
      //ignore: avoid_annotating_with_dynamic
      onTap: (dynamic media) => _navigateToMovie(media as Movie),
    ),
  );

  Widget _buildStreamingPlatforms() => Container(
    margin: const EdgeInsets.only(top: 30),
    child: StreamingPlatformCardHorizontalList(
      mediaType: MediaType.movies,
      viewAllSource: Urls.discoverMovie,
    ),
  );

  Widget _buildGenres() => Container(
    margin: const EdgeInsets.only(top: 30),
    child: GenresList(
      genres: _genres,
      mediaType: MediaType.movies,
      viewAllSource: Urls.discoverMovie,
    ),
  );

  @override
  String get screenName => "Movies";

  @override
  Future<void> initializeScreen() async {
    await _loadAllData();
  }

  @override
  void handleDispose() {
    _trendingController.dispose();
    _popularController.dispose();
    _topRatedController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRefresh: _refreshData,
      child: !_isLoading ? SingleChildScrollView(
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                _buildNowPlaying(),
                _buildRecentlyWatched(),
                _buildMediaCardHorizontalList(
                  title: "Trending",
                  controller: _trendingController,
                  viewAllSource: Urls.trendingMovies,
                ),
                _buildMediaCardHorizontalList(
                  title: "Popular",
                  controller: _popularController,
                  viewAllSource: Urls.popularMovies,
                ),
                _buildMediaCardHorizontalList(
                  title: "Top rated",
                  controller: _topRatedController,
                  viewAllSource: Urls.topRatedMovies,
                ),
                _buildStreamingPlatforms(),
                _buildGenres(),
              ],
            ),
          ),
        ),
      ) : const Center(child: CircularProgressIndicator()),
    ),
  );
}