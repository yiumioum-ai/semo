import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/components/vertical_media_list.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/search_results.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/screens/movie.dart';
import 'package:semo/screens/tv_show.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/enums/media_type.dart';
import 'package:semo/utils/navigation_helper.dart';

class ViewAll extends StatefulWidget {
  final String title;
  final String source;
  final Map<String, String>? parameters;
  final MediaType mediaType;

  const ViewAll({
    Key? key,
    required this.title,
    required this.source,
    this.parameters,
    required this.mediaType,
  }) : super(key: key);

  @override
  _ViewAllState createState() => _ViewAllState();
}

class _ViewAllState extends State<ViewAll> {
  // State
  bool _isConnectedToInternet = true;
  model.SearchResults _searchResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);

  // Pagination Controller using v5.x API
  late final PagingController<int, dynamic> _pagingController =
  PagingController<int, dynamic>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      await _fetchData(pageKey);
      return widget.mediaType == MediaType.movies
          ? (_searchResults.movies ?? [])
          : (_searchResults.tvShows ?? []);
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

  Future<void> _fetchData(int pageKey) async {
    try {
      final parameters = <String, String>{
        'page': '${_searchResults.page + 1}',
        ...?widget.parameters,
      };

      TMDBService tmdbService = TMDBService();
      final uri = Uri.parse(widget.source).replace(queryParameters: parameters);
      final response = await http.get(uri, headers: tmdbService.getHeaders());

      if (!kReleaseMode) print(response.body);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final searchResults = model.SearchResults.fromJson(
          widget.mediaType,
          json.decode(response.body),
        );

        setState(() => _searchResults = searchResults);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      if (!kReleaseMode) print('Error fetching data: $e');
      throw e;
    }
  }

  Future<void> _navigateToMedia(dynamic media) async {
    if (widget.mediaType == MediaType.movies) {
      await NavigationHelper.navigate(context, Movie(media as model.Movie));
    } else {
      await NavigationHelper.navigate(context, TvShow(media as model.TvShow));
    }
  }

  Widget _buildContent() {
    return VerticalMediaList<dynamic>(
      pagingController: _pagingController,
      itemBuilder: (context, media, index) {
        if (widget.mediaType == MediaType.movies) {
          final movie = media as model.Movie;
          return MediaCard(
            posterPath: movie.posterPath,
            title: movie.title,
            year: movie.releaseDate.split('-')[0],
            voteAverage: movie.voteAverage,
            onTap: () => _navigateToMedia(movie),
          );
        } else {
          final tvShow = media as model.TvShow;
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