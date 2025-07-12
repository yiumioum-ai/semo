import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/components/vertical_media_list.dart';
import 'package:semo/models/movie.dart';
import 'package:semo/models/search_results.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/screens/movie_screen.dart';
import 'package:semo/screens/tv_show_screen.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/enums/media_type.dart';
import 'package:semo/utils/navigation_helper.dart';

class ViewAllScreen extends StatefulWidget {
  final MediaType mediaType;
  final String title;
  final String source;
  final Map<String, String>? parameters;

  const ViewAllScreen({
    Key? key,
    required this.mediaType,
    required this.title,
    required this.source,
    this.parameters,
  }) : super(key: key);

  @override
  _ViewAllScreenState createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  // State
  bool _isConnectedToInternet = true;
  SearchResults _searchResults = SearchResults();
  final TMDBService _tmdbService = TMDBService();

  // Pagination Controller using v5.x API
  late final PagingController<int, dynamic> _pagingController =
  PagingController<int, dynamic>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      SearchResults results = await _tmdbService.searchFromUrl(widget.mediaType, widget.source, pageKey, widget.parameters);
      setState(() => _searchResults = results);
      return widget.mediaType == MediaType.movies
          ? (results.movies ?? <Movie>[])
          : (results.tvShows ?? <TvShow>[]);
    },
  );

  // Subscriptions
  late StreamSubscription _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _connectionSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _initConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'View All - ${widget.title}',
      );
    });
  }

  Future<void> _initConnectivity() async {
    _isConnectedToInternet = await InternetConnection().hasInternetAccess;
    _connectionSubscription = InternetConnection().onStatusChange.listen(
          (InternetStatus status) {
        if (mounted) {
          setState(() {
            _isConnectedToInternet = status == InternetStatus.connected;
          });
        }
      },
    );
  }

  Future<void> _navigateToMedia(dynamic media) async {
    if (widget.mediaType == MediaType.movies) {
      await NavigationHelper.navigate(context, MovieScreen(media as Movie));
    } else {
      await NavigationHelper.navigate(context, TvShowScreen(media as TvShow));
    }
  }

  Widget _buildContent() {
    return VerticalMediaList<dynamic>(
      pagingController: _pagingController,
      itemBuilder: (context, media, index) {
        if (widget.mediaType == MediaType.movies) {
          final movie = media as Movie;
          return MediaCard(
            posterPath: movie.posterPath,
            title: movie.title,
            year: movie.releaseDate.split('-')[0],
            voteAverage: movie.voteAverage,
            onTap: () => _navigateToMedia(movie),
          );
        } else {
          final tvShow = media as TvShow;
          return MediaCard(
            posterPath: tvShow.posterPath,
            title: tvShow.name,
            year: tvShow.firstAirDate.split('-')[0],
            voteAverage: tvShow.voteAverage,
            onTap: () => _navigateToMedia(tvShow),
          );
        }
      },
      crossAxisCount: 3,
      childAspectRatio: 0.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      padding: EdgeInsets.zero,
      emptyStateMessage: 'No ${widget.mediaType == MediaType.movies ? 'movies' : 'TV shows'} found',
      errorMessage: 'Failed to load ${widget.mediaType == MediaType.movies ? 'movies' : 'TV shows'}',
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_sharp,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'You have lost internet connection',
            style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          child: _isConnectedToInternet ? _buildContent() : _buildNoInternet(),
        ),
      ),
    );
  }
}