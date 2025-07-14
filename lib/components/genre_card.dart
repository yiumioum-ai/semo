import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/utils/urls.dart";

class GenreCard extends StatelessWidget {
  const GenreCard({
    super.key,
    required this.mediaType,
    required this.genre,
    this.onTap,
  });

  final Genre genre;
  final MediaType mediaType;
  final VoidCallback? onTap;

  final double _aspectRatio = 16 / 10;

  Widget _buildGenreCardContent(BuildContext context, {ImageProvider? image}) => SizedBox(
    width: MediaQuery.of(context).size.width * .6,
    child: Column(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: image == null ? Theme.of(context).cardColor : null,
                image: image != null ? DecorationImage(
                  image: image,
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: onTap,
                child: image == null ? const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.white54,
                    size: 48,
                  ),
                ) : Container(),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          child: Text(
            genre.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _buildFallback(BuildContext context, {required Widget child}) => Container(
    width: MediaQuery.of(context).size.width * .6,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: AspectRatio(
      aspectRatio: _aspectRatio,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        child: Center(child: child),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (genre.backdropPath == null || genre.backdropPath!.isEmpty) {
      return _buildGenreCardContent(context);
    }

    return CachedNetworkImage(
      imageUrl: "${Urls.getBestImageUrl(context)}${genre.backdropPath}",
      placeholder: (BuildContext context, String url) => _buildFallback(
        context,
        child: const CircularProgressIndicator(),
      ),
      imageBuilder: (BuildContext context, ImageProvider image) => _buildGenreCardContent(context, image: image),
      errorWidget: (BuildContext context, String url, Object error) => _buildFallback(
        context,
        child: const Icon(
          Icons.error,
          color: Colors.white54,
        ),
      ),
    );
  }
}