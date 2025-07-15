import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/media_card.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/utils/navigation_helper.dart";

class MediaCardHorizontalList extends StatelessWidget {
  const MediaCardHorizontalList({
    super.key,
    required this.title,
    required this.pagingController,
    required this.mediaType,
    required this.viewAllSource,
    required this.onTap,
  });

  final String title;
  final PagingController<int, dynamic> pagingController;
  final MediaType mediaType;
  final String viewAllSource;
  //ignore: avoid_annotating_with_dynamic
  final Function(dynamic media) onTap;

  @override
  Widget build(BuildContext context) => HorizontalMediaList<dynamic>(
    title: title,
    pagingController: pagingController,
    //ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) {
      late String mediaTitle;
      late String releaseYear;

      if (mediaType == MediaType.movies) {
        Movie movie = media as Movie;
        mediaTitle = movie.title;
        releaseYear = movie.releaseDate.split("-")[0];
      } else if (mediaType == MediaType.tvShows) {
        TvShow tvShow = media as TvShow;
        mediaTitle = tvShow.originalName;
        releaseYear = tvShow.firstAirDate.split("-")[0];
      }

      final String posterPath = media.posterPath;
      final double voteAverage = media.voteAverage;

      return Padding(
        padding: EdgeInsets.only(
          right: index < (pagingController.items?.length ?? 0) - 1 ? 18 : 0,
        ),
        child: MediaCard(
          posterPath: posterPath,
          title: mediaTitle,
          year: releaseYear,
          voteAverage: voteAverage,
          onTap: () => onTap(media),
        ),
      );
    },
    onViewAllTap: () => NavigationHelper.navigate(
      context,
      ViewAllScreen(
        title: title,
        source: viewAllSource,
        mediaType: mediaType,
      ),
    ),
  );
}
