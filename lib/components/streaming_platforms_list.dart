import "package:flutter/material.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/streaming_platform_card.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/models/streaming_platform.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/utils/navigation_helper.dart";

class StreamingPlatformsList extends StatelessWidget {
  StreamingPlatformsList({
    super.key,
    required this.mediaType,
    required this.viewAllSource,
  });

  final MediaType mediaType;
  final String viewAllSource;

  final List<StreamingPlatform> _streamingPlatforms = <StreamingPlatform>[
    StreamingPlatform(
      id: 8,
      logoPath: Assets.images.netflixLogo.path,
      name: "Netflix",
    ),
    StreamingPlatform(
      id: 9,
      logoPath: Assets.images.amazonPrimeVideoLogo.path,
      name: "Amazon Prime Video",
    ),
    StreamingPlatform(
      id: 2,
      logoPath: Assets.images.appleTvLogo.path,
      name: "Apple TV",
    ),
    StreamingPlatform(
      id: 337,
      logoPath: Assets.images.disneyPlusLogo.path,
      name: "Disney+",
    ),
    StreamingPlatform(
      id: 15,
      logoPath: Assets.images.huluLogo.path,
      name: "Hulu",
    ),
  ];

  @override
  Widget build(BuildContext context) => HorizontalMediaList<StreamingPlatform>(
    title: "Platforms",
    height: MediaQuery.of(context).size.height * 0.15,
    items: _streamingPlatforms,
    itemBuilder: (BuildContext context, StreamingPlatform streamingPlatform, int index) => Container(
      margin: EdgeInsets.only(
        right: index < _streamingPlatforms.length - 1 ? 18 : 0,
      ),
      child: StreamingPlatformCard(
        platform: streamingPlatform,
        onTap: () => NavigationHelper.navigate(
          context,
          ViewAllScreen(
            title: streamingPlatform.name,
            source: viewAllSource,
            parameters: <String, String>{
              "with_watch_providers": "${streamingPlatform.id}",
              "watch_region": "US",
            },
            mediaType: mediaType,
          ),
        ),
      ),
    ),
  );
}
