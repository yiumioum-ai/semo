import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:semo/components/carousel_poster.dart';
import 'package:semo/components/genre_card.dart';
import 'package:semo/components/horizontal_media_list.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/components/streaming_platform_card.dart';
import "package:semo/gen/assets.gen.dart";
import 'package:semo/models/genre.dart' as model;
import 'package:semo/models/movie.dart' as model;
import "package:semo/models/search_results.dart";
import 'package:semo/models/streaming_platform.dart';
import 'package:semo/screens/movie.dart';
import 'package:semo/screens/view_all.dart';
import 'package:semo/services/recently_watched_service.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/enums/media_type.dart';
import 'package:semo/utils/navigation_helper.dart';
import 'package:semo/components/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Movies extends StatefulWidget {
  const Movies({Key? key}) : super(key: key);

  @override
  _MoviesState createState() => _MoviesState();
}

class _MoviesState extends State<Movies> {
  // Services
  final TMDBService _tmdbService = TMDBService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();

  // State
  late Spinner _spinner;
  bool _isLoading = true;

  // Now Playing
  List<model.Movie> _nowPlaying = [];
  final CarouselSliderController _nowPlayingController = CarouselSliderController();
  int _currentNowPlayingIndex = 0;

  // Recently Watched
  List<model.Movie> _recentlyWatched = [];

  // Genres and Streaming Platforms
  List<model.Genre> _genres = [];
  final List<StreamingPlatform> _streamingPlatforms = [
    StreamingPlatform(id: 8, logoPath: Assets.images.netflixLogo.path, name: 'Netflix'),
    StreamingPlatform(id: 9, logoPath: Assets.images.amazonPrimeVideoLogo.path, name: 'Amazon Prime Video'),
    StreamingPlatform(id: 2, logoPath: Assets.images.appleTvLogo.path, name: 'Apple TV'),
    StreamingPlatform(id: 337, logoPath: Assets.images.disneyPlusLogo.path, name: 'Disney+'),
    StreamingPlatform(id: 15, logoPath: Assets.images.huluLogo.path, name: 'Hulu'),
  ];

  // Pagination Controllers using v5.x API
  late final PagingController<int, model.Movie> _trendingController = PagingController<int, model.Movie>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getTrendingMovies(pageKey);
      return result.movies ?? [];
    },
  );

  late final PagingController<int, model.Movie> _popularController = PagingController<int, model.Movie>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getPopularMovies(pageKey);
      return result.movies ?? [];
    },
  );

  late final PagingController<int, model.Movie> _topRatedController = PagingController<int, model.Movie>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getTopRatedMovies(pageKey);
      return result.movies ?? [];
    },
  );

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _trendingController.dispose();
    _popularController.dispose();
    _topRatedController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(screenName: 'Movies');
      await _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    _spinner.show();

    try {
      await Future.wait([
        _loadNowPlaying(),
        _loadRecentlyWatched(),
        _loadGenres(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to load data');
    } finally {
      _spinner.dismiss();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNowPlaying() async {
    final SearchResults results = await _tmdbService.getNowPlayingMovies();
    final List<model.Movie> movies = results.movies ?? <model.Movie>[];
    if (mounted) {
      setState(() {
        _nowPlaying = movies.length > 10 ? movies.sublist(0, 10) : movies;
      });
    }
  }

  Future<void> _loadRecentlyWatched() async {
    final recentlyWatchedIds = await _recentlyWatchedService.getRecentlyWatchedMovieIds();
    final movies = <model.Movie>[];

    for (final id in recentlyWatchedIds) {
      try {
        final movie = await _tmdbService.getMovieDetails(id);
        if (movie != null) {
          movies.add(movie);
        }
      } catch (e) {
        print('Failed to load movie $id: $e');
      }
    }

    if (mounted) {
      setState(() => _recentlyWatched = movies);
    }
  }

  Future<void> _loadGenres() async {
    final genres = await _tmdbService.getMovieGenres();
    if (mounted) {
      setState(() => _genres = genres);
    }
  }

  Future<void> _removeFromRecentlyWatched(model.Movie movie) async {
    try {
      await _recentlyWatchedService.removeMovieFromRecentlyWatched(movie.id);
      setState(() {
        _recentlyWatched.removeWhere((m) => m.id == movie.id);
      });
    } catch (e) {
      _showErrorSnackBar('Failed to remove from recently watched');
    }
  }

  Future<void> _refreshData() async {
    // Reset pagination controllers
    _trendingController.refresh();
    _popularController.refresh();
    _topRatedController.refresh();

    // Reset state
    setState(() {
      _isLoading = true;
      _nowPlaying = [];
      _recentlyWatched = [];
      _genres = [];
    });

    // Reload data
    await _loadAllData();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
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
  }

  Future<void> _navigateToMovie(model.Movie movie) async {
    final result = await NavigationHelper.navigate(context, Movie(movie));
    if (result == 'refresh') {
      await _loadRecentlyWatched();
    }
  }

  Widget _buildNowPlaying() {
    if (_nowPlaying.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _nowPlayingController,
          itemCount: _nowPlaying.length,
          options: CarouselOptions(
            aspectRatio: 2,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (int index, CarouselPageChangedReason reason) {
              setState(() => _currentNowPlayingIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return CarouselPoster(
              backdropPath: _nowPlaying[index].backdropPath,
              title: _nowPlaying[index].title,
              onTap: () => _navigateToMovie(_nowPlaying[index]),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: AnimatedSmoothIndicator(
            activeIndex: _currentNowPlayingIndex,
            count: _nowPlaying.length,
            effect: ExpandingDotsEffect(
              dotWidth: 10,
              dotHeight: 10,
              dotColor: Colors.white30,
              activeDotColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyWatchedSection() {
    if (_recentlyWatched.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Text(
              'Recently watched',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: const EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentlyWatched.length,
              itemBuilder: (context, index) {
                final movie = _recentlyWatched[index];
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _recentlyWatched.length - 1 ? 18 : 0,
                  ),
                  child: MediaCard(
                    posterPath: movie.posterPath,
                    title: movie.title,
                    year: movie.releaseDate.split('-')[0],
                    voteAverage: movie.voteAverage,
                    onTap: () => _navigateToMovie(movie),
                    showRemoveOption: true,
                    onRemove: () => _removeFromRecentlyWatched(movie),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingPlatforms() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Text(
              'Providers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.15,
            margin: const EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _streamingPlatforms.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _streamingPlatforms.length - 1 ? 18 : 0,
                  ),
                  child: StreamingPlatformCard(
                    platform: _streamingPlatforms[index],
                    onTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: _streamingPlatforms[index].name,
                        source: Urls.discoverMovie,
                        parameters: {
                          'with_watch_providers': '${_streamingPlatforms[index].id}',
                          'watch_region': 'US',
                        },
                        mediaType: MediaType.movies,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    if (_genres.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Text(
              'Genres',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            margin: const EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _genres.length - 1 ? 18 : 0,
                  ),
                  child: GenreCard(
                    mediaType: MediaType.movies,
                    genre: _genres[index],
                    onTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: _genres[index].name,
                        source: Urls.discoverMovie,
                        parameters: {'with_genres': '${_genres[index].id}'},
                        mediaType: MediaType.movies,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: _refreshData,
        child: !_isLoading
            ? SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildNowPlaying(),
                  _buildRecentlyWatchedSection(),
                  HorizontalMediaList<model.Movie>(
                    title: 'Trending',
                    source: Urls.trendingMovies,
                    pagingController: _trendingController,
                    itemBuilder: (c, m, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < (_trendingController.items?.length ?? 0) - 1 ? 18 : 0,
                      ),
                      child: MediaCard(
                        posterPath: m.posterPath,
                        title: m.title,
                        year: m.releaseDate.split('-')[0],
                        voteAverage: m.voteAverage,
                        onTap: () => _navigateToMovie(m),
                      ),
                    ),
                    onViewAllTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: 'Trending',
                        source: Urls.trendingMovies,
                        mediaType: MediaType.movies,
                      ),
                    ),
                  ),
                  HorizontalMediaList<model.Movie>(
                    title: 'Popular',
                    source: Urls.popularMovies,
                    pagingController: _popularController,
                    itemBuilder: (c, m, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < (_popularController.items?.length ?? 0) - 1 ? 18 : 0,
                      ),
                      child: MediaCard(
                        posterPath: m.posterPath,
                        title: m.title,
                        year: m.releaseDate.split('-')[0],
                        voteAverage: m.voteAverage,
                        onTap: () => _navigateToMovie(m),
                      ),
                    ),
                    onViewAllTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: 'Popular',
                        source: Urls.popularMovies,
                        mediaType: MediaType.movies,
                      ),
                    ),
                  ),
                  HorizontalMediaList<model.Movie>(
                    title: 'Top Rated',
                    source: Urls.topRatedMovies,
                    pagingController: _topRatedController,
                    itemBuilder: (c, m, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < (_topRatedController.items?.length ?? 0) - 1 ? 18 : 0,
                      ),
                      child: MediaCard(
                        posterPath: m.posterPath,
                        title: m.title,
                        year: m.releaseDate.split('-')[0],
                        voteAverage: m.voteAverage,
                        onTap: () => _navigateToMovie(m),
                      ),
                    ),
                    onViewAllTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: 'Top Rated',
                        source: Urls.topRatedMovies,
                        mediaType: MediaType.movies,
                      ),
                    ),
                  ),
                  _buildStreamingPlatforms(),
                  _buildGenres(),
                ],
              ),
            ),
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}