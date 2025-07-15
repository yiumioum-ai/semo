import "package:flutter/material.dart";
import "package:semo/components/genre_card.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/utils/navigation_helper.dart";

class GenresList extends StatelessWidget {
  const GenresList({
    super.key,
    required this.genres,
    required this.mediaType,
    required this.viewAllSource,
  });

  final List<Genre> genres;
  final MediaType mediaType;
  final String viewAllSource;

  @override
  Widget build(BuildContext context) => HorizontalMediaList<Genre>(
    title: "Genres",
    height: MediaQuery.of(context).size.height * 0.2,
    items: genres,
    itemBuilder: (BuildContext context, Genre genre, int index) => Container(
      margin: EdgeInsets.only(
        right: index < genres.length - 1 ? 18 : 0,
      ),
      child: GenreCard(
        genre: genre,
        mediaType: mediaType,
        onTap: () => NavigationHelper.navigate(
          context,
          ViewAllScreen(
            title: genre.name,
            source: viewAllSource,
            parameters: <String, String>{
              "with_genres": "${genre.id}",
            },
            mediaType: mediaType,
          ),
        ),
      ),
    ),
  );
}
