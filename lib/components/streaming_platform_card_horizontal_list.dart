import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/streaming_platform_card.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/streaming_platform.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/utils/navigation_helper.dart";
import "package:semo/utils/streaming_platforms.dart";

class StreamingPlatformCardHorizontalList extends StatelessWidget {
  const StreamingPlatformCardHorizontalList({
    super.key,
    required this.mediaType,
    required this.pagingControllers,
  });

  final MediaType mediaType;
  final Map<String, PagingController<int, dynamic>> pagingControllers;

  @override
  Widget build(BuildContext context) => HorizontalMediaList<StreamingPlatform>(
    title: "Platforms",
    height: MediaQuery.of(context).size.height * 0.15,
    items: streamingPlatforms,
    itemBuilder: (BuildContext context, StreamingPlatform streamingPlatform, int index) => Container(
      margin: EdgeInsets.only(
        right: index < streamingPlatforms.length - 1 ? 18 : 0,
      ),
      child: StreamingPlatformCard(
        platform: streamingPlatform,
        onTap: () => NavigationHelper.navigate(
          context,
          ViewAllScreen(
            title: streamingPlatform.name,
            pagingController: pagingControllers["${streamingPlatform.id}"],
            mediaType: mediaType,
          ),
        ),
      ),
    ),
  );
}
