import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/bloc/handlers/favorites_handler.dart";

class AppBloc extends Bloc<AppEvent, AppState> with FavoritesHandler {
  AppBloc() : super(const AppState()) {
    on<LoadFavorites>(onLoadFavorites);
    on<AddFavorite>(onAddFavorite);
    on<RemoveFavorite>(onRemoveFavorite);
    on<ClearError>(_onClearError);
  }

  void _onClearError(ClearError event, Emitter<AppState> emit) {
    emit(state.copyWith(error: null));
  }

  void loadInitialData() {
    add(LoadFavorites());
  }
}