import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/tv_show.dart';
import '../utils/urls.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final VoidCallback? onTap;
  final VoidCallback? onMarkWatched;
  final VoidCallback? onRemove;

  const EpisodeCard({
    Key? key,
    required this.episode,
    this.onTap,
    this.onMarkWatched,
    this.onRemove,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours} ${hours == 1 ? 'hr' : 'hrs'}${minutes > 0 ? ' ${minutes} ${minutes == 1 ? 'min' : 'mins'}' : ''}';
    } else {
      return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: Urls.getBestImageUrl(context) + episode.stillPath,
                  placeholder: (context, url) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  },
                  imageBuilder: (context, image) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: image,
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: episode.isRecentlyWatched
                                ? Column(
                              children: [
                                const Spacer(),
                                LinearProgressIndicator(
                                  value: episode.watchedProgress! / (episode.duration * 60),
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(context).primaryColor,
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              ],
                            )
                                : Container(),
                          ),
                        ),
                      ),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Align(
                            alignment: Alignment.center,
                            child: Icon(Icons.error, color: Colors.white54),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.name,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                        ),
                        const Padding(padding: EdgeInsets.only(top: 2)),
                        Text(
                          _formatDuration(Duration(minutes: episode.duration)),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall!
                              .copyWith(color: Colors.white54),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_watched':
                        onMarkWatched?.call();
                        break;
                      case 'remove':
                        onRemove?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_watched',
                      child: Text(
                        'Mark as watched',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    if (episode.isRecentlyWatched)
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove from watched',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18),
              child: Text(
                episode.overview,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall!
                    .copyWith(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}