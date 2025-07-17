import "dart:async";

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
          Movie? movie = await _tmdbService.getMovie(id);
          if (movie != null) {
            favorites.add(movie);
          }
        }
      } else if (widget.mediaType == MediaType.tvShows) {
        for (int id in favoritesIds) {
          TvShow? tvShow = await _tmdbService.getTvShow(id);
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

  void _removeFromFavorites(int id) {
    List<dynamic> favorites = _favorites;

    try {
      if (widget.mediaType == MediaType.movies) {
        unawaited(_favoritesService.removeMovie(id));
      } else if (widget.mediaType == MediaType.tvShows) {
        unawaited(_favoritesService.removeTvShow(id));
      }
    } catch (_) {}

    //ignore: avoid_annotating_with_dynamic
    favorites.removeWhere((dynamic media) => media.id == id);
    setState(() => _favorites = favorites);
  }

  //ignore: avoid_annotating_with_dynamic
  Widget _buildMediaCard(BuildContext context, dynamic media, int index) {
    VoidCallback onTap;

    if (widget.mediaType == MediaType.movies) {
      onTap = () => navigate(MovieScreen(media as Movie));
    } else {
      onTap = () => navigate(TvShowScreen(media as TvShow));
    }

    return MediaCard(
      media: media,
      mediaType: widget.mediaType,
      onTap: onTap,
      showRemoveOption: true,
      onRemove: () => _removeFromFavorites(media.id),
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
          //ignore: avoid_annotating_with_dynamic
          itemBuilder: (BuildContext context, dynamic media, int index) => _buildMediaCard(context, media, index),
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