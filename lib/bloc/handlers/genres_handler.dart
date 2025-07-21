import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/services/tmdb_service.dart";

mixin GenresHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadGenres(LoadGenres event, Emitter<AppState> emit) async {
    if (event.mediaType == MediaType.movies) {
      if (state.movieGenres != null && state.movieGenres!.isNotEmpty) {
        return;
      }

      emit(state.copyWith(
        isLoadingMovieGenres: true,
        error: null,
      ));

      try {
        final List<Genre> genres = await _tmdbService.getMovieGenres();
        emit(state.copyWith(
          movieGenres: genres,
          isLoadingMovieGenres: false,
        ));
      } catch (e, s) {
        _logger.e("Error loading movie genres", error: e, stackTrace: s);
        emit(state.copyWith(
          isLoadingMovieGenres: false,
          error: "Failed to load movie genres",
        ));
      }
    } else if (event.mediaType == MediaType.tvShows) {
      if (state.tvShowGenres != null &&  state.tvShowGenres!.isNotEmpty) {
        return;
      }

      emit(state.copyWith(
        isLoadingTvShowGenres: true,
        error: null,
      ));

      try {
        final List<Genre> genres = await _tmdbService.getTvShowGenres();
        emit(state.copyWith(
          tvShowGenres: genres,
          isLoadingTvShowGenres: false,
        ));
      } catch (e, s) {
        _logger.e("Error loading TV show genres", error: e, stackTrace: s);
        emit(state.copyWith(
          isLoadingTvShowGenres: false,
          error: "Failed to load TV show genres",
        ));
      }
    }
  }

  void onRefreshGenres(RefreshGenres event, Emitter<AppState> emit) {
    if (event.mediaType == MediaType.movies) {
      emit(state.copyWith(
        movieGenres: <Genre>[],
        isLoadingMovieGenres: false,
      ));
    } else if (event.mediaType == MediaType.tvShows) {
      emit(state.copyWith(
        tvShowGenres: <Genre>[],
        isLoadingTvShowGenres: false,
      ));
    }

    add(LoadGenres(event.mediaType));
  }
}