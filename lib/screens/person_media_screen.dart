import "dart:async";

import "package:flutter/material.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/models/tv_show.dart" ;
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";

class PersonMediaScreen extends BaseScreen {
  const PersonMediaScreen(this.person, {super.key});

  final Person person;

  @override
  BaseScreenState<PersonMediaScreen> createState() => _PersonMediaScreenState();
}

class _PersonMediaScreenState extends BaseScreenState<PersonMediaScreen> with TickerProviderStateMixin {
  final TMDBService _tmdbService = TMDBService();
  List<Movie> _movies = <Movie>[];
  List<TvShow> _tvShows = <TvShow>[];
  late final TabController _tabController = TabController(length: 2, vsync: this);
  MediaType _mediaType = MediaType.movies;
  bool _isLoading = true;

  Future<void> _getMedia() async {
    await Future.wait(<Future<void>>[
      _getMovies(),
      _getTvShows(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _getMovies() async {
    try {
      List<Movie> movies = await _tmdbService.getPersonMovies(widget.person);
      setState(() => _movies = movies);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to get movies");
      }
    }
  }

  Future<void> _getTvShows() async {
    try {
      List<TvShow> tvShows = await _tmdbService.getPersonTvShows(widget.person);
      setState(() => _tvShows = tvShows);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to get TV shows");
      }
    }
  }

  void onTabChanged() {
    MediaType mediaType = _tabController.index == 0 ? MediaType.movies : MediaType.tvShows;
    setState(() => _mediaType = mediaType);
  }

  Widget _buildMoviesList() => VerticalMediaList<Movie>(
    isLoading: _isLoading,
    items: _movies,
    itemBuilder: (BuildContext context, Movie movie, int index) => MediaCard(
      media: movie,
      mediaType: MediaType.movies,
      onTap: () => navigate(MovieScreen(movie)),
    ),
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    emptyStateMessage: "No movies found",
    errorMessage: "Failed to load movies",
    shrinkWrap: false,
    physics: const AlwaysScrollableScrollPhysics(),
  );

  Widget _buildTvShowsList() => VerticalMediaList<TvShow>(
    isLoading: _isLoading,
    items: _tvShows,
    itemBuilder: (BuildContext context, TvShow tvShow, int index) => MediaCard(
      media: tvShow,
      mediaType: MediaType.tvShows,
      onTap: () => navigate(TvShowScreen(tvShow)),
    ),
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    emptyStateMessage: "No TV shows found",
    errorMessage: "Failed to load TV shows",
    shrinkWrap: false,
    physics: const AlwaysScrollableScrollPhysics(),
  );

  @override
  String get screenName => "${widget.person.name} - ${_mediaType.toString()}";

  @override
  Future<void> initializeScreen() async {
    _tabController.addListener(onTabChanged);
    await _getMedia();
  }

  @override
  void handleDispose() {
    _tabController.removeListener(onTabChanged);
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.person.name),
      bottom: TabBar(
        controller: _tabController,
        tabs: const <Tab>[
          Tab(
            icon: Icon(Icons.movie),
            text: "Movies",
          ),
          Tab(
            icon: Icon(Icons.video_library),
            text: "TV Shows",
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(18),
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _buildMoviesList(),
            _buildTvShowsList(),
          ],
        ),
      ),
    ),
  );
}