import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/genre.dart' as model;
import '../services/tmdb_service.dart';
import '../utils/urls.dart';

class GenreCard extends StatelessWidget {
  final model.Genre genre;
  final bool isMovie;
  final VoidCallback? onTap;

  const GenreCard({
    Key? key,
    required this.genre,
    required this.isMovie,
    this.onTap,
  }) : super(key: key);

  Future<String> _getGenreBackdrop() async {
    try {
      final tmdbService = TMDBService();
      return await tmdbService.getGenreBackdrop(genre, isMovie: isMovie);
    } catch (e) {
      print('Error getting genre backdrop: $e');
      return '';
    }
  }

  Widget _buildGenreCardContent(BuildContext context, {required ImageProvider image}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .6,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 16 / 10,
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
                  onTap: onTap,
                  child: Container(),
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
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .6,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const AspectRatio(
        aspectRatio: 16 / 10,
        child: Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .6,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const AspectRatio(
        aspectRatio: 16 / 10,
        child: Center(
          child: Icon(Icons.error, color: Colors.white54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (genre.backdropPath != null) {
      return CachedNetworkImage(
        imageUrl: '${Urls.getBestImageUrl(context)}${genre.backdropPath}',
        placeholder: (context, url) => _buildPlaceholder(context),
        imageBuilder: (context, image) => _buildGenreCardContent(context, image: image),
        errorWidget: (context, url, error) => _buildError(context),
      );
    }

    return FutureBuilder<String>(
      future: _getGenreBackdrop(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildError(context);
        }

        return CachedNetworkImage(
          imageUrl: '${Urls.getBestImageUrl(context)}${snapshot.data!}',
          placeholder: (context, url) => _buildPlaceholder(context),
          imageBuilder: (context, image) => _buildGenreCardContent(context, image: image),
          errorWidget: (context, url, error) => _buildError(context),
        );
      },
    );
  }
}