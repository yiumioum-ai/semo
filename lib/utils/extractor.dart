import "dart:math";

import "package:flutter/foundation.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/server.dart";
import "package:semo/models/stream.dart";
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

  static List<Server> servers = <Server>[
    Server(name: "Random"),
    Server(name: "AutoEmbed", extractor: AutoEmbed()),
    Server(name: "EmbedSu", extractor: EmbedSu()),
    Server(name: "KissKh", extractor: KissKh()),
    //Server(name: "MoviesApi", extractor: MoviesApi()),
    Server(name: "RiveStream", extractor: RiveStream()),
    //Server(name: "Whvx", extractor: Whvx()),
  ];

  Future<MediaStream> getStream() async {
    late Map<String, dynamic> parameters;
    Random random = Random();
    String serverName = Preferences().getServer();
    MediaStream stream = MediaStream();
    dynamic extractor;

    if (serverName != "Random") {
      Server server = servers.firstWhere((Server server) => server.name == serverName);
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

    while (stream.url == null && servers.isNotEmpty) {
      int randomIndex = random.nextInt(servers.length);

      if (serverName == "Random" && extractor == null) {
        Server server = servers[randomIndex];
        extractor = server.extractor;
      }

      stream = await extractor.extract(parameters);

      if (stream.url == null) {
        if (serverName == "Random") {
          servers.removeAt(randomIndex);
        }
        stream = MediaStream();
      }
    }

    if (!kReleaseMode) {
      print("$serverName: ${stream.url}");
    }

    return stream;
  }
}