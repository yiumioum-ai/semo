import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/media_info.dart";
import "package:semo/components/media_poster.dart";
import "package:semo/components/person_card.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/models/search_results.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/person_media_screen.dart";
import "package:semo/screens/player_screen.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/services/favorites_service.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/subtitle_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/extractor.dart";
import "package:semo/utils/navigation_helper.dart";
import "package:semo/utils/urls.dart";

class MovieScreen extends BaseScreen {
  const MovieScreen(this.movie, {super.key});

  final Movie movie;

  @override
  BaseScreenState<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends BaseScreenState<MovieScreen> {
  late Movie _movie;
  final TMDBService _tmdbService = TMDBService();
  final FavoritesService _favoritesService = FavoritesService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  final SubtitleService _subtitleService = SubtitleService();
  bool _isFavorite = false;
  bool _isLoading = true;
  late final PagingController<int, Movie> _recommendationsController = PagingController<int, Movie>(
    getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getRecommendations(
        MediaType.movies,
        _movie.id,
        pageKey,
      );
      return results.movies ?? <Movie>[];
    },
  );
  late final PagingController<int, Movie> _similarController = PagingController<int, Movie>(
    getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults result = await _tmdbService.getSimilar(
        MediaType.movies,
        _movie.id,
        pageKey,
      );
      return result.movies ?? <Movie>[];
    },
  );
  
  Future<void> _loadMovieDetails() async {
    try {
      await Future.wait(<Future<void>>[
        _checkIfFavorite(),
        _checkIfRecentlyWatched(),
        _loadTrailer(),
        _loadDuration(),
        _loadCast(),
      ]);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load movie details");
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkIfFavorite() async {
    final List<int> favorites = await _favoritesService.getMovies();
    setState(() => _isFavorite = favorites.contains(_movie.id));
  }

  Future<void> _checkIfRecentlyWatched() async {
    final int? progress = await _recentlyWatchedService.getMovieProgress(_movie.id);
    if (progress != null) {
      setState(() {
        _movie.isRecentlyWatched = true;
        _movie.watchedProgress = progress;
      });
    }
  }

  Future<void> _loadTrailer() async {
    final String? url = await _tmdbService.getTrailerUrl(MediaType.movies, _movie.id);
    if (url != null) {
      setState(() => _movie.trailerUrl = url);
    }
  }

  Future<void> _loadDuration() async {
    final int? duration = await _tmdbService.getMovieDuration(_movie.id);
    if (duration != null) {
      setState(() => _movie.duration = duration);
    }
  }

  Future<void> _loadCast() async {
    final List<Person> cast = await _tmdbService.getCast(MediaType.movies, _movie.id);
    setState(() => _movie.cast = cast);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    try {
      if (_isFavorite) {
        await _favoritesService.removeMovie(_movie.id);
      } else {
        await _favoritesService.addMovie(_movie.id);
      }
    } catch (_) {
      setState(() => _isFavorite = !_isFavorite);
      if (mounted) {
        showSnackBar(context, "Failed to update favorites");
      }
    }
  }

  Future<void> _playMovie() async {
    spinner.show();

    try {
      final Extractor extractor = Extractor(movie: _movie);
      final MediaStream? stream = await extractor.getStream();
      final List<File> subtitles = await _subtitleService.getSubtitles(_movie.id);

      spinner.dismiss();

      if (stream != null && stream.url != null) {
        final dynamic result = await navigate(
          PlayerScreen(
            id: _movie.id,
            title: _movie.title,
            stream: stream,
            subtitles: subtitles,
            mediaType: MediaType.movies,
          ),
        );

        if (result != null) {
          _handlePlayerResult(result);
        }
      } else {
        if (mounted) {
          showSnackBar(context, "No stream link found.");
        }
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load stream.");
      }
    }

    spinner.dismiss();
  }

  void _handlePlayerResult(Map<String, dynamic> result) {
    if (mounted) {
      if (result["error"] != null) {
        showSnackBar(context, "Playback error. Try again");
      } else if (result["progress"] != null) {
        setState(() {
          _movie.isRecentlyWatched = true;
          _movie.watchedProgress = result["progress"];
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      _movie.trailerUrl = null;
      _movie.cast = null;
    });

    _recommendationsController.refresh();
    _similarController.refresh();

    await _loadMovieDetails();
  }

  String _formatDuration(Duration d) {
    final int hours = d.inHours;
    final int mins = d.inMinutes.remainder(60);

    if (hours > 0) {
      return "$hours ${hours == 1 ? "hr" : "hrs"}${mins > 0 ? " $mins ${mins == 1 ? "min" : "mins"}" : ''}";
    }

    return "$mins ${mins == 1 ? "min" : "mins"}";
  }

  @override
  String get screenName => "Movie - ${widget.movie.title}";

  @override
  Future<void> initializeScreen() async {
    _movie = widget.movie;
    await _loadMovieDetails();
  }

  @override
  void handleDispose() {
    _recommendationsController.dispose();
    _similarController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () => Navigator.pop(context, "refresh"),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          color: _isFavorite ? Colors.red : Colors.white,
          onPressed: _toggleFavorite,
        ),
      ],
    ),
    body: !_isLoading ? SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              MediaPoster(
                backdropPath: _movie.backdropPath,
                trailerUrl: _movie.trailerUrl,
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MediaInfo(
                      title: _movie.title,
                      subtitle: _movie.duration != null
                          ? "${_movie.releaseDate.split("-")[0]} · ${_formatDuration(Duration(minutes: _movie.duration ?? 0))}"
                          : _movie.releaseDate.split("-")[0],
                      overview: _movie.overview,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _playMovie,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.play_arrow,
                              size: 25,
                            ),
                            SizedBox(width: 5),
                            Text("Play"),
                          ],
                        ),
                      ),
                    ),
                    if (_movie.cast?.isNotEmpty == true)
                      ...<Widget>[
                        const SizedBox(height: 30),
                        HorizontalMediaList<Person>(
                          title: "Cast",
                          items: _movie.cast!,
                          itemBuilder: (BuildContext context, Person person, int index) => Padding(
                            padding: EdgeInsets.only(
                              right: index < _movie.cast!.length - 1 ? 18 : 0,
                            ),
                            child: PersonCard(
                              person: person,
                              onTap: () => NavigationHelper.navigate(
                                context,
                                PersonMediaScreen(person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    const SizedBox(height: 30),
                    HorizontalMediaList<Movie>(
                      title: "Recommendations",
                      pagingController: _recommendationsController,
                      itemBuilder: (BuildContext context, Movie movie, int index) => Padding(
                        padding: EdgeInsets.only(
                          right: index < (_recommendationsController.items?.length ?? 0) - 1 ? 18 : 0,
                        ),
                        child: MediaCard(
                          posterPath: movie.posterPath,
                          title: movie.title,
                          year: movie.releaseDate.split("-")[0],
                          voteAverage: movie.voteAverage,
                          onTap: () => navigate(MovieScreen(movie)),
                        ),
                      ),
                      onViewAllTap: () => navigate(
                        ViewAllScreen(
                          title: "Recommendations",
                          source: Urls.getMovieRecommendations(_movie.id),
                          mediaType: MediaType.movies,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    HorizontalMediaList<Movie>(
                      title: "Similar",
                      pagingController:
                      _similarController,
                      itemBuilder: (BuildContext context, Movie movie, int index) => Padding(
                        padding: EdgeInsets.only(
                          right: index < (_similarController.items?.length ?? 0) - 1 ? 18 : 0,
                        ),
                        child: MediaCard(
                          posterPath: movie.posterPath,
                          title: movie.title,
                          year: movie.releaseDate.split("-")[0],
                          voteAverage: movie.voteAverage,
                          onTap: () => navigate(MovieScreen(movie)),
                        ),
                      ),
                      onViewAllTap: () => navigate(
                        ViewAllScreen(
                          mediaType: MediaType.movies,
                          title: "Similar",
                          source: Urls.getMovieSimilar(_movie.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ) : const Center(child: CircularProgressIndicator())
  );
}