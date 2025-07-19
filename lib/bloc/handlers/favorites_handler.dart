import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/services/favorites_service.dart";
import "package:semo/services/tmdb_service.dart";

mixin FavoritesHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();
  final FavoritesService _favoritesService = FavoritesService();

  Future<void> onLoadFavorites(LoadFavorites event, Emitter<AppState> emit) async {
    if ((state.favoriteMovies != null && state.favoriteTvShows != null) || state.isLoadingFavorites) {
      return;
    }

    emit(state.copyWith(
      isLoadingFavorites: true,
      error: null,
    ));

    try {
      final Map<String, List<int>> favorites = _convertToIntListMap(await _favoritesService.getFavorites());

      final List<int> movieIds = favorites[MediaType.movies.toJsonField()] ?? <int>[];
      final List<int> tvShowIds = favorites[MediaType.tvShows.toJsonField()] ?? <int>[];

      final List<Movie> favoriteMovies = await _fetchMoviesByIds(movieIds);
      final List<TvShow> favoriteTvShows = await _fetchTvShowsByIds(tvShowIds);

      emit(state.copyWith(
        favoriteMovies: favoriteMovies,
        favoriteTvShows: favoriteTvShows,
        isLoadingFavorites: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading favorites", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingFavorites: false,
        error: "Failed to load favorites",
      ));
    }
  }

  // ignore: avoid_annotating_with_dynamic
  Future<void> _addFavorite(dynamic media, MediaType mediaType) async {
    try {
      final int id = _getMediaId(media);
      if (mediaType == MediaType.movies) {
        await _favoritesService.addMovie(id);
      } else if (mediaType == MediaType.tvShows) {
        await _favoritesService.addTvShow(id);
      }
    } catch (e, s) {
      _logger.e("Error adding favorite", error: e, stackTrace: s);
      rethrow;
    }
  }

  void onAddFavorite(AddFavorite event, Emitter<AppState> emit) {
    final int mediaId = _getMediaId(event.media);

    if (event.mediaType == MediaType.movies) {
      final List<Movie> currentFavoriteMovies = List<Movie>.from(state.favoriteMovies ?? <Movie>[]);

      if (currentFavoriteMovies.any((Movie movie) => movie.id == mediaId)) {
        return;
      }

      if (event.media is Movie) {
        currentFavoriteMovies.add(event.media as Movie);

        try {
          unawaited(_addFavorite(event.media, event.mediaType));
        } catch (_) {}

        emit(state.copyWith(favoriteMovies: currentFavoriteMovies));
      }
    } else if (event.mediaType == MediaType.tvShows) {
      final List<TvShow> currentFavoriteTvShows = List<TvShow>.from(state.favoriteTvShows ?? <TvShow>[]);

      if (currentFavoriteTvShows.any((TvShow tvShow) => tvShow.id == mediaId)) {
        return;
      }

      if (event.media is TvShow) {
        currentFavoriteTvShows.add(event.media as TvShow);

        try {
          unawaited(_addFavorite(event.media, event.mediaType));
        } catch (_) {}

        emit(state.copyWith(favoriteTvShows: currentFavoriteTvShows));
      }
    }
  }

  // ignore: avoid_annotating_with_dynamic
  Future<void> _removeFavorite(dynamic media, MediaType mediaType) async {
    try {
      final int id = _getMediaId(media);
      if (mediaType == MediaType.movies) {
        await _favoritesService.removeMovie(id);
      } else if (mediaType == MediaType.tvShows) {
        await _favoritesService.removeTvShow(id);
      }
    } catch (e, s) {
      _logger.e("Error removing favorite", error: e, stackTrace: s);
      rethrow;
    }
  }

  void onRemoveFavorite(RemoveFavorite event, Emitter<AppState> emit) {
    final int mediaId = _getMediaId(event.media);

    if (event.mediaType == MediaType.movies) {
      final List<Movie> currentFavoriteMovies = List<Movie>.from(state.favoriteMovies ?? <Movie>[]);

      currentFavoriteMovies.removeWhere((Movie movie) => movie.id == mediaId);

      try {
        unawaited(_removeFavorite(event.media, event.mediaType));
      } catch (_) {}

      emit(state.copyWith(favoriteMovies: currentFavoriteMovies));
    } else if (event.mediaType == MediaType.tvShows) {
      final List<TvShow> currentFavoriteTvShows = List<TvShow>.from(state.favoriteTvShows ?? <TvShow>[]);

      currentFavoriteTvShows.removeWhere((TvShow tvShow) => tvShow.id == mediaId);

      try {
        unawaited(_removeFavorite(event.media, event.mediaType));
      } catch (_) {}

      emit(state.copyWith(favoriteTvShows: currentFavoriteTvShows));
    }
  }

  // ignore: avoid_annotating_with_dynamic
  int _getMediaId(dynamic media) {
    if (media is Movie) {
      return media.id;
    } else if (media is TvShow) {
      return media.id;
    } else {
      throw Exception("Invalid media type: ${media.runtimeType}");
    }
  }

  // ignore: prefer_expression_function_bodies
  Map<String, List<int>> _convertToIntListMap(Map<String, dynamic> favorites) {
    // ignore: avoid_annotating_with_dynamic
    return favorites.map((String key, dynamic value) => MapEntry<String, List<int>>(key, List<int>.from(value)));
  }

  Future<List<Movie>> _fetchMoviesByIds(List<int> ids) async {
    List<Movie> movies = <Movie>[];

    for (final int id in ids) {
      if (state.movies != null && state.movies!.any((Movie movie) => movie.id == id)) {
        movies.add(state.movies!.firstWhere((Movie movie) => movie.id == id));
      } else {
        try {
          final Movie? movie = await _tmdbService.getMovie(id);

          if (movie != null) {
            movies.add(movie);
          } else {
            _logger.w("Movie with ID $id not found");
          }
        } catch (e, s) {
          _logger.e("Error fetching movie with ID $id", error: e, stackTrace: s);
        }
      }
    }

    return movies;
  }

  Future<List<TvShow>> _fetchTvShowsByIds(List<int> ids) async {
    List<TvShow> tvShows = <TvShow>[];

    for (final int id in ids) {
      if (state.tvShows != null && state.tvShows!.any((TvShow tvShow) => tvShow.id == id)) {
        tvShows.add(state.tvShows!.firstWhere((TvShow tvShow) => tvShow.id == id));
      } else {
        try {
          final TvShow? tvShow = await _tmdbService.getTvShow(id);

          if (tvShow != null) {
            tvShows.add(tvShow);
          } else {
            _logger.w("TV Show with ID $id not found");
          }
        } catch (e, s) {
          _logger.e("Error fetching TV Show with ID $id", error: e, stackTrace: s);
        }
      }
    }

    return tvShows;
  }
}