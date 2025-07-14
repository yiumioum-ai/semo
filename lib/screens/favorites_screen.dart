import "package:flutter/material.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
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
  BaseScreenState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends BaseScreenState<FavoritesScreen> {
  List<dynamic> _favorites = <dynamic>[];
  final FavoritesService _favoritesService = FavoritesService();
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = true;

  Future<void> _getFavorites() async {
    List<dynamic> favorites = <dynamic>[];

    try {
      final List<int> favoritesIds = widget.mediaType == MediaType.movies
          ? await _favoritesService.getMovies()
          : await _favoritesService.getTvShows();

      if (widget.mediaType == MediaType.movies) {
        for (int id in favoritesIds) {
          Movie? movie = await _tmdbService.getMovieDetails(id);
          if (movie != null) {
            favorites.add(movie);
          }
        }
      } else if (widget.mediaType == MediaType.tvShows) {
        for (int id in favoritesIds) {
          TvShow? tvShow = await _tmdbService.getTvShowDetails(id);
          if (tvShow != null) {
            favorites.add(tvShow);
          }
        }
      }

      setState(() => _favorites = favorites);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "An error occurred.");
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _removeFromFavorites(int id) async {
    List<dynamic> favorites = _favorites;

    try {
      if (widget.mediaType == MediaType.movies) {
        await _favoritesService.removeMovie(id);
      } else if (widget.mediaType == MediaType.tvShows) {
        await _favoritesService.removeTvShow(id);
      }

      //ignore: always_specify_types
      favorites.removeWhere((media) => media.id == id);
      setState(() => _favorites = favorites);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "An error occurred.");
      }
    }
  }

  //ignore: always_specify_types
  Widget _buildMediaCard(BuildContext context, var media, int index) {
    String posterPath;
    String title;
    String year;
    double voteAverage;
    VoidCallback onTap;

    if (widget.mediaType == MediaType.movies) {
      final Movie movie = media as Movie;
      posterPath = movie.posterPath;
      title = movie.title;
      year = movie.releaseDate.split("-")[0];
      voteAverage = movie.voteAverage;
      onTap = () => navigate(MovieScreen(movie));
    } else {
      final TvShow tvShow = media as TvShow;
      posterPath = tvShow.posterPath;
      title = tvShow.name;
      year = tvShow.firstAirDate.split("-")[0];
      voteAverage = tvShow.voteAverage;
      onTap = () => navigate(TvShowScreen(tvShow));
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
            await _removeFromFavorites(media.id);
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
  String get screenName => "Favorites";

  @override
  Future<void> initializeScreen() async {
    await _getFavorites();
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