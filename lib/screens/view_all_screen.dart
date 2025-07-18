import "dart:async";

import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/search_results.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";

class ViewAllScreen extends BaseScreen {
  const ViewAllScreen({
    super.key,
    required this.mediaType,
    required this.title,
    required this.source,
    this.parameters,
  });
  
  final MediaType mediaType;
  final String title;
  final String source;
  final Map<String, String>? parameters;

  @override
  BaseScreenState<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends BaseScreenState<ViewAllScreen> {
  final TMDBService _tmdbService = TMDBService();
  late final PagingController<int, dynamic> _pagingController =
  PagingController<int, dynamic>(
    getNextPageKey: (PagingState<int, dynamic> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      SearchResults results = await _tmdbService.searchFromUrl(
        widget.mediaType,
        widget.source,
        pageKey,
        widget.parameters,
      );
      return widget.mediaType == MediaType.movies
          ? (results.movies ?? <Movie>[])
          : (results.tvShows ?? <TvShow>[]);
    },
  );
  
  //ignore: avoid_annotating_with_dynamic
  Future<void> _navigateToMedia(dynamic media) async {
    if (widget.mediaType == MediaType.movies) {
      await navigate(MovieScreen(media as Movie));
    } else {
      await navigate(TvShowScreen(media as TvShow));
    }
  }

  Widget _buildGrid() => VerticalMediaList<dynamic>(
    pagingController: _pagingController,
    //ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) => MediaCard(
      media: media,
      mediaType: widget.mediaType,
      onTap: () => _navigateToMedia(media),
    ),
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    padding: EdgeInsets.zero,
    emptyStateMessage: "No ${widget.mediaType.toString()} found",
    errorMessage: "Failed to load ${widget.mediaType.toString()}",
  );

  @override
  String get screenName => "View All - ${widget.title}";

  @override
  void handleDispose() {
    _pagingController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: SafeArea(
      child: Container(
        padding: const EdgeInsets.all(18),
        child: _buildGrid(),
      ),
    ),
  );
}