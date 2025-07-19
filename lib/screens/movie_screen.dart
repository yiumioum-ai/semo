import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/media_info.dart";
import "package:semo/components/media_poster.dart";
import "package:semo/components/person_card_horizontal_list.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/models/search_results.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/player_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/stream_extractor/extractor.dart";
import "package:semo/services/subtitle_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";
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
        _getCompleteMovieDetails(),
        _checkIfRecentlyWatched(),
        _loadTrailer(),
        _loadCast(),
      ]);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load movie details");
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getCompleteMovieDetails() async {
    final Movie? movie = await _tmdbService.getMovie(_movie.id);
    if (movie != null) {
      setState(() => _movie = movie);
    }
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

  Future<void> _loadCast() async {
    final List<Person> cast = await _tmdbService.getCast(MediaType.movies, _movie.id);
    setState(() => _movie.cast = cast);
  }

  void _toggleFavorite() {
    try {
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite
          ? RemoveFavorite(_movie, MediaType.movies)
          : AddFavorite(_movie, MediaType.movies);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _playMovie() async {
    spinner.show();

    try {
      final MediaStream? stream = await StreamExtractor.getStream(movie: _movie);

      if (stream != null && stream.url.isNotEmpty) {
        stream.subtitleFiles = await _subtitleService.getSubtitles(_movie.id);

        spinner.dismiss();

        final dynamic result = await navigate(
          PlayerScreen(
            tmdbId: _movie.id,
            title: _movie.title,
            stream: stream,
            mediaType: MediaType.movies,
          ),
        );

        if (result != null) {
          _handlePlayerResult(result);
        }
      } else {
        if (mounted) {
          showSnackBar(context, "No stream found");
        }
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load stream");
      }
    }

    spinner.dismiss();
  }

  void _handlePlayerResult(Map<String, dynamic> result) {
    try {
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
    } catch (_) {}
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

  Widget _buildPlayButton() => Container(
    width: double.infinity,
    height: 50,
    margin: const EdgeInsets.only(top: 30),
    child: ElevatedButton(
      onPressed: _playMovie,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.play_arrow,
            size: 28,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            "Play",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 22,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPersonCardHorizontalList() {
    if (_movie.cast == null || _movie.cast!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: PersonCardHorizontalList(
        title: "Cast",
        people: _movie.cast!,
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
      onTap: (dynamic media) => navigate(
        MovieScreen(media as Movie),
      ),
    ),
  );

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
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (mounted) {
        _isFavorite = state.favoriteMovies?.any((Movie movie) => movie.id == _movie.id) ?? false;
      }

      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) => Scaffold(
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
                        subtitle: "${_movie.releaseDate.split("-")[0]} · ${_formatDuration(Duration(minutes: _movie.duration))}",
                        overview: _movie.overview,
                      ),
                      _buildPlayButton(),
                      _buildPersonCardHorizontalList(),
                      _buildMediaCardHorizontalList(
                        title: "Recommendations",
                        controller: _recommendationsController,
                        viewAllSource: Urls.getMovieRecommendations(_movie.id),
                      ),
                      _buildMediaCardHorizontalList(
                        title: "Similar",
                        controller: _similarController,
                        viewAllSource: Urls.getMovieSimilar(_movie.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ) : const Center(child: CircularProgressIndicator()),
    ),
  );
}