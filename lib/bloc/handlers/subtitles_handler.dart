import "dart:async";
import "dart:io";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/services/subtitle_service.dart";

mixin SubtitlesHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final SubtitleService _subtitleService = SubtitleService();

  Future<void> onLoadMovieSubtitles(LoadMovieSubtitles event, Emitter<AppState> emit) async {
    String movieId = event.movieId.toString();
    final bool areSubtitlesExtracted = state.movieSubtitles?.containsKey(movieId) ?? false;

    if (areSubtitlesExtracted) {
      return;
    }

    try {
      final List<File> subtitles = await _subtitleService.getSubtitles(
        event.movieId,
        locale: event.locale,
      );

      if (subtitles.isEmpty) {
        _logger.w("No ${event.locale} subtitles found for movie ${event.movieId}");
      }

      final Map<String, List<File>> updatedSubtitles = Map<String, List<File>>.from(state.movieSubtitles ?? <String, List<File>>{});
      updatedSubtitles[movieId] = subtitles;
      
      emit(state.copyWith(
        movieSubtitles: updatedSubtitles,
      ));
    } catch (e, s) {
      _logger.e("Error extracting ${event.locale} subtitles for movie $movieId", error: e, stackTrace: s);

      emit(state.copyWith(
        error: "Failed to extract ${event.locale} subtitles",
      ));
    }
  }

  Future<void> onLoadEpisodeSubtitles(LoadEpisodeSubtitles event, Emitter<AppState> emit) async {
    String episodeId = event.episodeId.toString();
    final bool areSubtitlesExtracted = state.episodeSubtitles?.containsKey(episodeId) ?? false;

    if (areSubtitlesExtracted) {
      return;
    }

    try {
      final List<File> subtitles = await _subtitleService.getSubtitles(
        event.tvShowId,
        seasonNumber: event.seasonNumber,
        episodeNumber: event.episodeNumber,
        locale: event.locale,
      );

      if (subtitles.isEmpty) {
        _logger.w("No ${event.locale} subtitles found for episode ${event.episodeId}");
      }

      final Map<String, List<File>> updatedSubtitles = Map<String, List<File>>.from(state.episodeSubtitles ?? <String, List<File>>{});
      updatedSubtitles[episodeId] = subtitles;

      emit(state.copyWith(
        episodeSubtitles: updatedSubtitles,
      ));
    } catch (e, s) {
      _logger.e("Error extracting ${event.locale} subtitles for episode $episodeId", error: e, stackTrace: s);

      emit(state.copyWith(
        error: "Failed to extract ${event.locale} subtitles",
      ));
    }
  }
}