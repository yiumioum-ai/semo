import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/urls.dart';

class MediaPoster extends StatelessWidget {
  final String backdropPath;
  final String? trailerUrl;
  final String playTrailerText;

  const MediaPoster({
    super.key,
    required this.backdropPath,
    this.trailerUrl,
    this.playTrailerText = 'Play trailer',
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: Urls.getBestImageUrl(context) + backdropPath,
      placeholder: (context, url) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width * 0.4,
          child: const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),
        );
      },
      imageBuilder: (context, image) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    color: Colors.white,
                    onPressed: trailerUrl != null ? () async {
                      await launchUrl(
                        Uri.parse(trailerUrl!),
                        mode: LaunchMode.externalNonBrowserApplication,
                      );
                    } : null,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Text(
                    playTrailerText,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}