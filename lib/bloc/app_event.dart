import "package:semo/enums/media_type.dart";
import "package:semo/models/movie.dart";

abstract class AppEvent {
  const AppEvent();
}

class LoadMovies extends AppEvent {}

class RefreshMovies extends AppEvent {}

class AddIncompleteMovies extends AppEvent {
  const AddIncompleteMovies(this.movies);

  final List<Movie> movies;
}

class LoadGenres extends AppEvent {
  const LoadGenres(this.mediaType);

  final MediaType mediaType;
}

class RefreshGenres extends AppEvent {
  const RefreshGenres(this.mediaType);

  final MediaType mediaType;
}

class LoadRecentlyWatched extends AppEvent {}

class GetMovieProgress extends AppEvent {
  const GetMovieProgress(this.movieId);

  final int movieId;
}

class GetEpisodeProgress extends AppEvent {
  const GetEpisodeProgress(this.tvShowId, this.seasonId, this.episodeId);

  final int tvShowId;
  final int seasonId;
  final int episodeId;
}

class UpdateMovieProgress extends AppEvent {
  const UpdateMovieProgress(this.movieId, this.progress);

  final int movieId;
  final int progress;
}

class UpdateEpisodeProgress extends AppEvent {
  const UpdateEpisodeProgress(this.tvShowId, this.seasonId, this.episodeId, this.progress);

  final int tvShowId;
  final int seasonId;
  final int episodeId;
  final int progress;
}

class DeleteMovieProgress extends AppEvent {
  const DeleteMovieProgress(this.movieId);

  final int movieId;
}

class DeleteEpisodeProgress extends AppEvent {
  const DeleteEpisodeProgress(this.tvShowId, this.seasonId, this.episodeId);

  final int tvShowId;
  final int seasonId;
  final int episodeId;
}

class DeleteTvShowProgress extends AppEvent {
  const DeleteTvShowProgress(this.tvShowId);

  final int tvShowId;
}

class HideTvShowProgress extends AppEvent {
  const HideTvShowProgress(this.tvShowId);

  final int tvShowId;
}

class LoadFavorites extends AppEvent {}

class AddFavorite extends AppEvent {
  const AddFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class RemoveFavorite extends AppEvent {
  const RemoveFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class ClearError extends AppEvent {}