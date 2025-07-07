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
import 'package:semo/models/genre.dart' as model;
import 'package:semo/models/streaming_platform.dart';
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/screens/tv_show.dart';
import 'package:semo/screens/view_all.dart';
import 'package:semo/services/recently_watched_service.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/navigation_helper.dart';
import 'package:semo/components/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TvShows extends StatefulWidget {
  const TvShows({Key? key}) : super(key: key);

  @override
  _TvShowsState createState() => _TvShowsState();
}

class _TvShowsState extends State<TvShows> {
  // Services
  final TMDBService _tmdbService = TMDBService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();

  // State
  late Spinner _spinner;
  bool _isLoading = true;

  // On The Air
  List<model.TvShow> _onTheAir = [];
  final CarouselSliderController _onTheAirController = CarouselSliderController();
  int _currentOnTheAirIndex = 0;

  // Recently Watched
  List<model.TvShow> _recentlyWatched = [];

  // Genres and Streaming Platforms
  List<model.Genre> _genres = [];
  final List<StreamingPlatform> _streamingPlatforms = [
    StreamingPlatform(id: 8, logoPath: '/netflix.png', name: 'Netflix'),
    StreamingPlatform(id: 9, logoPath: '/amazon_prime_video.png', name: 'Amazon Prime Video'),
    StreamingPlatform(id: 2, logoPath: '/apple_tv.png', name: 'Apple TV'),
    StreamingPlatform(id: 337, logoPath: '/disney_plus.png', name: 'Disney+'),
    StreamingPlatform(id: 15, logoPath: '/hulu.png', name: 'Hulu'),
  ];

  // Pagination Controllers using v5.x API
  late final PagingController<int, model.TvShow> _popularController = PagingController<int, model.TvShow>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getPopularTvShows(pageKey);
      return result.tvShows ?? [];
    },
  );

  late final PagingController<int, model.TvShow> _topRatedController = PagingController<int, model.TvShow>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = await _tmdbService.getTopRatedTvShows(pageKey);
      return result.tvShows ?? [];
    },
  );

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _popularController.dispose();
    _topRatedController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(screenName: 'TV Shows');
      await _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    _spinner.show();

    try {
      await Future.wait([
        _loadOnTheAir(),
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

  Future<void> _loadOnTheAir() async {
    final tvShows = await _tmdbService.getOnTheAirTvShows();
    if (mounted) {
      setState(() {
        _onTheAir = tvShows.length > 10 ? tvShows.sublist(0, 10) : tvShows;
      });
    }
  }

  Future<void> _loadRecentlyWatched() async {
    final recentlyWatchedIds = await _recentlyWatchedService.getRecentlyWatchedTvShowIds();
    final tvShows = <model.TvShow>[];

    for (final id in recentlyWatchedIds) {
      try {
        final tvShow = await _tmdbService.getTvShowDetails(id);
        if (tvShow != null) {
          tvShows.add(tvShow);
        }
      } catch (e) {
        print('Failed to load TV show $id: $e');
      }
    }

    if (mounted) {
      setState(() => _recentlyWatched = tvShows);
    }
  }

  Future<void> _loadGenres() async {
    final genres = await _tmdbService.getTvShowGenres();
    if (mounted) {
      setState(() => _genres = genres);
    }
  }

  Future<void> _removeFromRecentlyWatched(model.TvShow tvShow) async {
    try {
      await _recentlyWatchedService.removeTvShowFromRecentlyWatched(tvShow.id);
      setState(() {
        _recentlyWatched.removeWhere((tv) => tv.id == tvShow.id);
      });
    } catch (e) {
      _showErrorSnackBar('Failed to remove from recently watched');
    }
  }

  Future<void> _refreshData() async {
    // Reset pagination controllers
    _popularController.refresh();
    _topRatedController.refresh();

    // Reset state
    setState(() {
      _isLoading = true;
      _onTheAir = [];
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

  Future<void> _navigateToTvShow(model.TvShow tvShow) async {
    final result = await NavigationHelper.navigate(context, TvShow(tvShow));
    if (result == 'refresh') {
      await _loadRecentlyWatched();
    }
  }

  Widget _buildOnTheAir() {
    if (_onTheAir.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _onTheAirController,
          itemCount: _onTheAir.length,
          options: CarouselOptions(
            aspectRatio: 2,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (int index, CarouselPageChangedReason reason) {
              setState(() => _currentOnTheAirIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return CarouselPoster(
              backdropPath: _onTheAir[index].backdropPath,
              title: _onTheAir[index].name,
              onTap: () => _navigateToTvShow(_onTheAir[index]),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: AnimatedSmoothIndicator(
            activeIndex: _currentOnTheAirIndex,
            count: _onTheAir.length,
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
                final tvShow = _recentlyWatched[index];
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _recentlyWatched.length - 1 ? 18 : 0,
                  ),
                  child: MediaCard(
                    posterPath: tvShow.posterPath,
                    title: tvShow.name,
                    year: tvShow.firstAirDate.split('-')[0],
                    voteAverage: tvShow.voteAverage,
                    onTap: () => _navigateToTvShow(tvShow),
                    showRemoveOption: true,
                    onRemove: () => _removeFromRecentlyWatched(tvShow),
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
                        source: Urls.discoverTvShow,
                        parameters: {
                          'with_watch_providers': '${_streamingPlatforms[index].id}',
                          'watch_region': 'US',
                        },
                        pageType: PageType.tv_shows,
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
                    genre: _genres[index],
                    isMovie: false,
                    onTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: _genres[index].name,
                        source: Urls.discoverTvShow,
                        parameters: {'with_genres': '${_genres[index].id}'},
                        pageType: PageType.tv_shows,
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
                  _buildOnTheAir(),
                  _buildRecentlyWatchedSection(),
                  HorizontalMediaList<model.TvShow>(
                    title: 'Popular',
                    source: Urls.popularTvShows,
                    pagingController: _popularController,
                    itemBuilder: (c, tv, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < (_popularController.items?.length ?? 0) - 1 ? 18 : 0,
                      ),
                      child: MediaCard(
                        posterPath: tv.posterPath,
                        title: tv.name,
                        year: tv.firstAirDate.split('-')[0],
                        voteAverage: tv.voteAverage,
                        onTap: () => _navigateToTvShow(tv),
                      ),
                    ),
                    onViewAllTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: 'Popular',
                        source: Urls.popularTvShows,
                        pageType: PageType.tv_shows,
                      ),
                    ),
                  ),
                  HorizontalMediaList<model.TvShow>(
                    title: 'Top Rated',
                    source: Urls.topRatedTvShows,
                    pagingController: _topRatedController,
                    itemBuilder: (c, tv, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < (_topRatedController.items?.length ?? 0) - 1 ? 18 : 0,
                      ),
                      child: MediaCard(
                        posterPath: tv.posterPath,
                        title: tv.name,
                        year: tv.firstAirDate.split('-')[0],
                        voteAverage: tv.voteAverage,
                        onTap: () => _navigateToTvShow(tv),
                      ),
                    ),
                    onViewAllTap: () => NavigationHelper.navigate(
                      context,
                      ViewAll(
                        title: 'Top Rated',
                        source: Urls.topRatedTvShows,
                        pageType: PageType.tv_shows,
                      ),
                    ),
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
}