import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/bloc/handlers/favorites_handler.dart";
import "package:semo/bloc/handlers/genres_handler.dart";
import "package:semo/bloc/handlers/movies_handler.dart";
import "package:semo/bloc/handlers/recently_watched_handler.dart";
import "package:semo/enums/media_type.dart";

class AppBloc extends Bloc<AppEvent, AppState> with MoviesHandler, GenresHandler, RecentlyWatchedHandler, FavoritesHandler {
  AppBloc() : super(const AppState()) {
    on<LoadMovies>(onLoadMovies);
    on<RefreshMovies>(onRefreshMovies);
    on<AddIncompleteMovies>(onAddIncompleteMovies);
    on<LoadGenres>(onLoadGenres);
    on<RefreshGenres>(onRefreshGenres);
    on<LoadRecentlyWatched>(onLoadRecentlyWatched);
    on<GetMovieProgress>(onGetMovieProgress);
    on<GetEpisodeProgress>(onGetEpisodeProgress);
    on<UpdateMovieProgress>(onUpdateMovieProgress);
    on<UpdateEpisodeProgress>(onUpdateEpisodeProgress);
    on<DeleteMovieProgress>(onDeleteMovieProgress);
    on<DeleteEpisodeProgress>(onDeleteEpisodeProgress);
    on<DeleteTvShowProgress>(onDeleteTvShowProgress);
    on<HideTvShowProgress>(onHideTvShowProgress);
    on<LoadFavorites>(onLoadFavorites);
    on<AddFavorite>(onAddFavorite);
    on<RemoveFavorite>(onRemoveFavorite);
    on<ClearError>(_onClearError);
  }

  void _onClearError(ClearError event, Emitter<AppState> emit) {
    emit(state.copyWith(error: null));
  }

  void loadInitialData() {
    add(LoadMovies());
    add(const LoadGenres(MediaType.movies));
    add(const LoadGenres(MediaType.tvShows));
    add(LoadRecentlyWatched());
    add(LoadFavorites());
  }
}