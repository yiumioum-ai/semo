import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:semo/components/media_card.dart';
import 'package:semo/models/movie.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/screens/movie_screen.dart';
import 'package:semo/screens/tv_show_screen.dart';
import 'package:semo/services/recent_searches_service.dart';
import 'package:semo/services/tmdb_service.dart';
import 'package:semo/enums/media_type.dart';
import 'package:semo/utils/navigation_helper.dart';

import '../components/vertical_media_list.dart' show VerticalMediaList;

class SearchScreen extends StatefulWidget {
  final MediaType mediaType;

  const SearchScreen({
    Key? key,
    required this.mediaType,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Services
  final TMDBService _tmdbService = TMDBService();
  final RecentSearchesService _recentSearchesService = RecentSearchesService();

  // State
  late MediaType _mediaType;
  bool _isSearched = false;
  bool _isConnectedToInternet = true;

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  String _currentQuery = '';

  // Pagination Controller using v5.x API
  late final PagingController<int, dynamic> _searchPagingController = PagingController<int, dynamic>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      if (_currentQuery.isEmpty) return [];

      final result = _mediaType == MediaType.movies
          ? await _tmdbService.searchMovies(_currentQuery, pageKey)
          : await _tmdbService.searchTvShows(_currentQuery, pageKey);

      return _mediaType == MediaType.movies
          ? (result.movies ?? [])
          : (result.tvShows ?? []);
    },
  );

  // Subscriptions
  late StreamSubscription _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _mediaType = widget.mediaType;
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectionSubscription.cancel();
    _searchPagingController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _initConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(screenName: 'Search');
      await _loadRecentSearches();
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

  Future<void> _loadRecentSearches() async {
    final searches = await _recentSearchesService.getRecentSearches(_mediaType);
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  Future<void> _addToRecentSearches(String query) async {
    try {
      await _recentSearchesService.add(_mediaType, query);
      await _loadRecentSearches();
    } catch (e) {
      _showErrorSnackBar('Failed to save search');
    }
  }

  Future<void> _removeFromRecentSearches(String query) async {
    try {
      await _recentSearchesService.remove(_mediaType, query);
      await _loadRecentSearches();
    } catch (e) {
      _showErrorSnackBar('Failed to remove search');
    }
  }

  void _submitSearch(String query, {required bool isRecentSearch}) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      if (isRecentSearch) _searchController.text = trimmedQuery;
      _isSearched = true;
      _currentQuery = trimmedQuery;
    });

    if (!isRecentSearch) {
      _addToRecentSearches(trimmedQuery);
    }

    _searchPagingController.refresh();
  }

  void _clearSearch() {
    setState(() {
      _isSearched = false;
      _currentQuery = '';
      _searchController.clear();
    });
    _searchPagingController.refresh();
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

  Future<void> _navigateToMedia(dynamic media) async {
    if (_mediaType == MediaType.movies) {
      await NavigationHelper.navigate(context, MovieScreen(media));
    } else {
      await NavigationHelper.navigate(context, TvShowScreen(media));
    }
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: BackButton(
        onPressed: () => Navigator.pop(context, 'refresh'),
      ),
      title: TextField(
        controller: _searchController,
        readOnly: !_isConnectedToInternet || _isSearched,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: Theme.of(context).textTheme.displayMedium,
        decoration: InputDecoration(
          hintText: 'Type here...',
          hintStyle: Theme.of(context)
              .textTheme
              .displayMedium!
              .copyWith(color: Colors.white54),
          border: InputBorder.none,
        ),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (query) => _submitSearch(
          query,
          isRecentSearch: _recentSearches.contains(query.trim()),
        ),
      ),
      actions: [
        if (_isSearched)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for ${_mediaType == MediaType.movies ? 'movies' : 'TV shows'}',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium!
                  .copyWith(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final query = _recentSearches[index];
        return ListTile(
          leading: const Icon(
            Icons.history,
            color: Colors.white54,
          ),
          title: Text(
            query,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white54,
            ),
            onPressed: () => _removeFromRecentSearches(query),
          ),
          onTap: () => _submitSearch(query, isRecentSearch: true),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return VerticalMediaList<dynamic>(
      pagingController: _searchPagingController,
      itemBuilder: (context, media, index) {
        if (_mediaType == MediaType.movies) {
          final movie = media.Movie;
          return MediaCard(
            posterPath: movie.posterPath,
            title: movie.title,
            year: movie.releaseDate.split('-')[0],
            voteAverage: movie.voteAverage,
            onTap: () => _navigateToMedia(movie),
          );
        } else {
          final tvShow = media.TvShow;
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
      emptyStateMessage: 'No results found for "$_currentQuery"',
      errorMessage: 'Failed to load search results',
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
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
            style: Theme.of(context)
                .textTheme
                .displayMedium!
                .copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildSearchAppBar(),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          child: _isConnectedToInternet
              ? (_isSearched ? _buildSearchResults() : _buildRecentSearches())
              : _buildNoInternet(),
        ),
      ),
    );
  }
}