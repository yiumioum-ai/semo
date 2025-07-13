import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:logger/logger.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/utils/urls.dart";

class GenreCard extends StatefulWidget {
  const GenreCard({
    super.key,
    required this.mediaType,
    required this.genre,
    this.onTap,
  });

  final Genre genre;
  final MediaType mediaType;
  final VoidCallback? onTap;

  @override
  State<GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<GenreCard> {
  final TMDBService _tmdbService = TMDBService();
  final Logger _logger = Logger();
  final double _aspectRatio = 16 / 10;
  late final Future<String> _genreBackdropFuture;

  @override
  void initState() {
    super.initState();
    _genreBackdropFuture = _getGenreBackdrop();
  }

  Future<String> _getGenreBackdrop() async {
    try {
      return await _tmdbService.getGenreBackdrop(widget.mediaType, widget.genre);
    } catch (e, s) {
      _logger.e("Error getting genre backdrop", error: e, stackTrace: s);
      return "";
    }
  }

  Widget _buildGenreCardContent(BuildContext context, {required ImageProvider image}) => SizedBox(
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
                image: DecorationImage(
                  image: image,
                  fit: BoxFit.cover,
                ),
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: widget.onTap,
                child: Container(),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          child: Text(
            widget.genre.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _buildPlaceholder(BuildContext context) => Container(
    width: MediaQuery.of(context).size.width * .6,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: AspectRatio(
      aspectRatio: _aspectRatio,
      child: const Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    ),
  );

  Widget _buildError(BuildContext context) => Container(
    width: MediaQuery.of(context).size.width * .6,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: AspectRatio(
      aspectRatio: _aspectRatio,
      child: const Center(
        child: Icon(
          Icons.error,
          color: Colors.white54,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.genre.backdropPath != null) {
      return CachedNetworkImage(
        imageUrl: "${Urls.getBestImageUrl(context)}${widget.genre.backdropPath}",
        placeholder: (BuildContext context, String url) => _buildPlaceholder(context),
        imageBuilder: (BuildContext context, ImageProvider image) => _buildGenreCardContent(context, image: image),
        errorWidget: (BuildContext context, String url, Object error) => _buildError(context),
      );
    }

    return FutureBuilder<String>(
      future: _genreBackdropFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildError(context);
        }

        return CachedNetworkImage(
          imageUrl: "${Urls.getBestImageUrl(context)}${snapshot.data!}",
          placeholder: (BuildContext context, String url) => _buildPlaceholder(context),
          imageBuilder: (BuildContext context, ImageProvider image) => _buildGenreCardContent(context, image: image),
          errorWidget: (BuildContext context, String url, Object error) => _buildError(context),
        );
      },
    );
  }
}