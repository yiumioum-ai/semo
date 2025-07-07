import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/urls.dart';

class MediaCard extends StatelessWidget {
  final String posterPath;
  final String title;
  final String year;
  final double voteAverage;
  final VoidCallback? onTap;
  final bool showRemoveOption;
  final VoidCallback? onRemove;

  const MediaCard({
    Key? key,
    required this.posterPath,
    required this.title,
    required this.year,
    required this.voteAverage,
    this.onTap,
    this.showRemoveOption = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: '${Urls.image185}$posterPath',
            placeholder: (context, url) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              );
            },
            imageBuilder: (context, image) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: onTap,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 8,
                                  ),
                                  margin: const EdgeInsets.only(
                                    top: 5,
                                    right: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Text(
                                    '$voteAverage',
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    if (showRemoveOption && onRemove != null)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              onRemove!();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                'Remove',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            errorWidget: (context, url, error) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.error, color: Colors.white54),
                ),
              );
            },
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          margin: const EdgeInsets.only(top: 10),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          margin: const EdgeInsets.only(top: 5),
          child: Text(
            year,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .displaySmall!
                .copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}