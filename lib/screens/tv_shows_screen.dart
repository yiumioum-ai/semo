import "dart:async";

import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/carousel_slider.dart";
import "package:semo/components/genres_horizontal_list.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/components/streaming_platform_card_horizontal_list.dart";
import "package:semo/models/genre.dart";
import "package:semo/models/search_results.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/urls.dart";

class TvShowsScreen extends BaseScreen {
  const TvShowsScreen({super.key});

  @override
  BaseScreenState<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends BaseScreenState<TvShowsScreen> {
  final TMDBService _tmdbService = TMDBService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  bool _isLoading = true;
  List<TvShow> _onTheAir = <TvShow>[];
  int _currentOnTheAirIndex = 0;
  List<TvShow> _recentlyWatched = <TvShow>[];
  List<Genre> _genres = <Genre>[];
  late final PagingController<int, TvShow> _popularController = PagingController<int, TvShow>(
    getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getPopularTvShows(pageKey);
      return results.tvShows ?? <TvShow>[];
    },
  );
  late final PagingController<int, TvShow> _topRatedController = PagingController<int, TvShow>(
    getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getTopRatedTvShows(pageKey);
      return results.tvShows ?? <TvShow>[];
    },
  );

  Future<void> _loadAllData() async {
    await Future.wait(<Future<void>>[
      _loadOnTheAir(),
      _loadRecentlyWatched(),
      _loadGenres(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOnTheAir() async {
    try {
      final SearchResults results = await _tmdbService.getOnTheAirTvShows();
      final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
      if (mounted) {
        setState(() => _onTheAir = tvShows.length > 10 ? tvShows.sublist(0, 10) : tvShows);
      }
    } catch (_) {
     if (mounted) {
       showSnackBar(context, "Failed to load On The Air");
     }
    }
  }

  Future<void> _loadRecentlyWatched() async {
    try {
      final List<int> recentlyWatchedIds = await _recentlyWatchedService.getTvShowIds();
      final List<TvShow> tvShows = <TvShow>[];

      for (final int id in recentlyWatchedIds) {
        final TvShow? tvShow = await _tmdbService.getTvShow(id);
        if (tvShow != null) {
          tvShows.add(tvShow);
        }
      }

      if (mounted) {
        setState(() => _recentlyWatched = tvShows);
      }
    } catch (_) {}
  }

  Future<void> _loadGenres() async {
    try {
      final List<Genre> genres = await _tmdbService.getTvShowGenres();
      if (mounted) {
        setState(() => _genres = genres);
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load genres");
      }
    }
  }

  void _removeFromRecentlyWatched(TvShow tvShow) {
    final List<TvShow> recentlyWatched = _recentlyWatched;

    try {
      unawaited(_recentlyWatchedService.removeTvShow(tvShow.id));
    } catch (_) {}

    recentlyWatched.removeWhere((TvShow tv) => tv.id == tvShow.id);
    setState(() => _recentlyWatched = recentlyWatched);
  }

  Future<void> _refreshData() async {

    setState(() {
      _isLoading = true;
      _onTheAir = <TvShow>[];
      _recentlyWatched = <TvShow>[];
      _genres = <Genre>[];
    });

    _popularController.refresh();
    _topRatedController.refresh();

    await _loadAllData();
  }

  Future<void> _navigateToTvShow(TvShow tvShow) async {
    final dynamic result = await navigate(TvShowScreen(tvShow));
    if (result == "refresh") {
      await _loadRecentlyWatched();
    }
  }

  Widget _buildOnTheAir() {
    if (_onTheAir.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      items: _onTheAir,
      currentItemIndex: _currentOnTheAirIndex,
      onItemChanged: (int index) => setState(() => _currentOnTheAirIndex = index),
      onItemTap: (int index) => _navigateToTvShow(_onTheAir[index]),
      mediaType: MediaType.tvShows,
    );
  }

  Widget _buildRecentlyWatchedSection() {
    if (_recentlyWatched.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: HorizontalMediaList<TvShow>(
        title: "Recently watched",
        items: _recentlyWatched,
        itemBuilder: (BuildContext context, TvShow tvShow, int index) => Padding(
          padding: EdgeInsets.only(
            right: index < (_recentlyWatched.length) - 1 ? 18 : 0,
          ),
          child: MediaCard(
            media: tvShow,
            mediaType: MediaType.tvShows,
            onTap: () => _navigateToTvShow(tvShow),
            showRemoveOption: true,
            onRemove: () => _removeFromRecentlyWatched(tvShow),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({
    required PagingController<int, TvShow> controller,
    required String title,
    required String viewAllSource,
  }) => Padding(
    padding: const EdgeInsets.only(top: 30),
    child: MediaCardHorizontalList(
      title: title,
      pagingController: controller,
      viewAllSource: viewAllSource,
      mediaType: MediaType.tvShows,
      //ignore: avoid_annotating_with_dynamic
      onTap: (dynamic media) => _navigateToTvShow(media as TvShow),
    ),
  );

  Widget _buildStreamingPlatforms() => Container(
    margin: const EdgeInsets.only(top: 30),
    child: StreamingPlatformCardHorizontalList(
      mediaType: MediaType.tvShows,
      viewAllSource: Urls.discoverTvShow,
    ),
  );

  Widget _buildGenres() => Container(
    margin: const EdgeInsets.only(top: 30),
    child: GenresList(
      genres: _genres,
      mediaType: MediaType.tvShows,
      viewAllSource: Urls.discoverTvShow,
    ),
  );

  @override
  String get screenName => "TV Shows";

  @override
  Future<void> initializeScreen() async {
    await _loadAllData();
  }

  @override
  void handleDispose() {
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
                _buildOnTheAir(),
                _buildRecentlyWatchedSection(),
                _buildMediaCardHorizontalList(
                  title: "Popular",
                  controller: _popularController,
                  viewAllSource: Urls.popularTvShows,
                ),
                _buildMediaCardHorizontalList(
                  title: "Top rated",
                  controller: _topRatedController,
                  viewAllSource: Urls.topRatedTvShows,
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