import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";

class AppState {
  const AppState({
    this.movies,
    this.tvShows,
    this.favoriteMovies,
    this.favoriteTvShows,
    this.isLoadingFavorites = false,
    this.error,
  });

  final List<Movie>? movies;
  final List<TvShow>? tvShows;
  final List<Movie>? favoriteMovies;
  final List<TvShow>? favoriteTvShows;
  final bool isLoadingFavorites;
  final String? error;

  AppState copyWith({
    List<Movie>? movies,
    List<TvShow>? tvShows,
    List<Movie>? favoriteMovies,
    List<TvShow>? favoriteTvShows,
    bool? isLoadingFavorites,
    String? error,
  }) => AppState(
    movies: movies ?? this.movies,
    tvShows: tvShows ?? this.tvShows,
    favoriteMovies: favoriteMovies ?? this.favoriteMovies,
    favoriteTvShows: favoriteTvShows ?? this.favoriteTvShows,
    isLoadingFavorites: isLoadingFavorites ?? this.isLoadingFavorites,
    error: error ?? this.error,
  );
}