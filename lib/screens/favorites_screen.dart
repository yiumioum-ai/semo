import "package:flutter/material.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart" as model;
import "package:semo/models/tv_show.dart" as model;
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/services/favorites_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/components/pop_up_menu.dart";

class FavoritesScreen extends BaseScreen {
  const FavoritesScreen({
    super.key,
    required this.mediaType,
  });
  
  final MediaType mediaType;

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends BaseScreenState<FavoritesScreen> {
  List<dynamic> _favorites = <dynamic>[];
  final FavoritesService _favoritesService = FavoritesService();
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = true;
  
  @override
  String get screenName => "Favorites";

  Future<void> _getFavorites() async {
    List<dynamic> favorites = <dynamic>[];

    try {
      final List<int> favoritesIds = widget.mediaType == MediaType.movies
          ? await _favoritesService.getFavoriteMovies()
          : await _favoritesService.getFavoriteTvShows();

      if (widget.mediaType == MediaType.movies) {
        for (int id in favoritesIds) {
          model.Movie? movie = await _tmdbService.getMovieDetails(id);
          if (movie != null) {
            favorites.add(movie);
          }
        }
      } else if (widget.mediaType == MediaType.tvShows) {
        for (int id in favoritesIds) {
          model.TvShow? tvShow = await _tmdbService.getTvShowDetails(id);
          if (tvShow != null) {
            favorites.add(tvShow);
          }
        }
      }

      setState(() => _favorites = favorites);
    } catch (_) {
      showSnackBar("An error occurred.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _removeFromRecentlyWatched(int id) async {
    List<dynamic> favorites = _favorites;

    try {
      if (widget.mediaType == MediaType.movies) {
        await _favoritesService.removeMovieFromFavorites(id);
      } else if (widget.mediaType == MediaType.tvShows) {
        await _favoritesService.removeTvShowFromFavorites(id);
      }

      //ignore: always_specify_types
      favorites.removeWhere((media) => media.id == id);
      setState(() => _favorites = favorites);
    } catch (_) {
      showSnackBar("An error occurred.");
    }
  }

  @override
  Future<void> initializeScreen() async {
    await _getFavorites();
  }

  //ignore: always_specify_types
  Widget _buildMediaCard(BuildContext context, var media, int index) {
    String posterPath;
    String title;
    String year;
    double voteAverage;
    VoidCallback onTap;

    if (widget.mediaType == MediaType.movies) {
      final model.Movie movie = media as model.Movie;
      posterPath = movie.posterPath;
      title = movie.title;
      year = movie.releaseDate.split("-")[0];
      voteAverage = movie.voteAverage;
      onTap = () => navigate(MovieScreen(media));
    } else {
      final model.TvShow tvShow = media as model.TvShow;
      posterPath = tvShow.posterPath;
      title = tvShow.name;
      year = tvShow.firstAirDate.split("-")[0];
      voteAverage = tvShow.voteAverage;
      onTap = () => navigate(TvShowScreen(media));
    }

    return PopupMenuContainer<String>(
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: "remove",
          child: Text(
            "Remove",
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ],
      onItemSelected: (String? action) async {
        if (action != null) {
          if (action == "remove") {
            await _removeFromRecentlyWatched(media.id);
          }
        }
      },
      child: MediaCard(
        posterPath: posterPath,
        title: title,
        year: year,
        voteAverage: voteAverage,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(18),
          child: VerticalMediaList<dynamic>(
            isLoading: _isLoading,
            items: _favorites,
            //ignore: always_specify_types
            itemBuilder: (BuildContext context, media, int index) => _buildMediaCard(context, media, index),
            crossAxisCount: 3,
            childAspectRatio: 0.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            emptyStateMessage: "You don't have any favorites",
            errorMessage: "Failed to load favorites",
            shrinkWrap: false,
            physics: const AlwaysScrollableScrollPhysics(),
          ),
        ),
      ),
    );
}