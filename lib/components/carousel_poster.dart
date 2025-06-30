import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/urls.dart';

class CarouselPoster extends StatelessWidget {
  final String backdropPath;
  final String title;
  final VoidCallback? onTap;

  const CarouselPoster({
    Key? key,
    required this.backdropPath,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: '${Urls.getBestImageUrl(context)}${backdropPath}',
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: const Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.transparent,
                    Theme.of(context).primaryColor.withOpacity(.1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      left: 14,
                      bottom: 8,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}