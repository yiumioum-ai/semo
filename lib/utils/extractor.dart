import "dart:math";

import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/utils/extractors/auto_embed.dart";
import "package:semo/utils/extractors/embedsu.dart";
import "package:semo/utils/extractors/kisskh.dart";
import "package:semo/utils/extractors/rive_stream.dart";
import "package:semo/utils/preferences.dart";

class Extractor {
  Extractor({
    this.movie,
    this.episode,
  });

  Movie? movie;
  Episode? episode;
  
  static final List<StreamingServer> _servers = <StreamingServer>[
    const StreamingServer(name: "Random", extractor: null),
    StreamingServer(name: "AutoEmbed", extractor: AutoEmbed()),
    StreamingServer(name: "EmbedSu", extractor: EmbedSu()),
    StreamingServer(name: "KissKh", extractor: KissKh()),
    //StreamingServer(name: "MoviesApi", extractor: MoviesApi()),
    StreamingServer(name: "RiveStream", extractor: RiveStream()),
    //StreamingServer(name: "Whvx", extractor: Whvx()),
  ];
  final Logger _logger = Logger();

  Future<MediaStream?> getStream() async {
    late Map<String, dynamic> parameters;
    Random random = Random();
    String serverName = Preferences().getServer();
    MediaStream? stream;
    dynamic extractor;

    if (serverName != "Random") {
      StreamingServer server = _servers.firstWhere((StreamingServer server) => server.name == serverName);
      extractor = server.extractor;
    }

    if (movie != null) {
      parameters = <String, dynamic>{
        "tmdbId": movie?.id,
        "title": movie?.title,
      };
    } else if (episode != null) {
      parameters = <String, dynamic>{
        "tmdbId": episode?.tvShowId,
        "title": episode?.tvShowName,
        "season": episode?.season,
        "episode": episode?.number,
      };
    }

    while (stream?.url == null && _servers.isNotEmpty) {
      int randomIndex = random.nextInt(_servers.length);

      if (serverName == "Random" && extractor == null) {
        StreamingServer server = _servers[randomIndex];
        extractor = server.extractor;
      }

      stream = await extractor.extract(parameters);

      if (stream?.url == null) {
        _logger.w("Stream not found.\nStreamingServer: $serverName");
        if (serverName == "Random") {
          _servers.removeAt(randomIndex);
        }
        stream = null;
      }
    }

    _logger.i("Stream found.\nStreamingServer: $serverName\nUrl: ${stream?.url}");

    return stream;
  }

  static List<StreamingServer> getServers() => _servers;
}