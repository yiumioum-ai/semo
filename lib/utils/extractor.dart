import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:semo/models/movie.dart';
import 'package:semo/models/server.dart';
import 'package:semo/models/stream.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/utils/extractors/auto_embed.dart';
import 'package:semo/utils/extractors/embedsu.dart';
import 'package:semo/utils/extractors/kisskh.dart';
import 'package:semo/utils/extractors/rive_stream.dart';
import 'package:semo/utils/extractors/whvx.dart';
import 'package:semo/utils/preferences.dart';

class Extractor {
  static List<Server> servers = [
    Server(name: 'Random', extractor: null),
    Server(name: 'AutoEmbed', extractor: AutoEmbed()),
    Server(name: 'EmbedSu', extractor: EmbedSu()),
    Server(name: 'KissKh', extractor: KissKh()),
    //Server(name: 'MoviesApi', extractor: MoviesApi()),
    Server(name: 'RiveStream', extractor: RiveStream()),
    Server(name: 'Whvx', extractor: Whvx()),
  ];

  Movie? movie;
  Episode? episode;

  Extractor({
    this.movie,
    this.episode,
  });

  Future<MediaStream> getStream() async {
    late Map<String, dynamic> parameters;

    if (movie != null) {
      parameters = {
        'tmdbId': movie!.id,
        'title': movie!.title,
      };
    } else if (episode != null) {
      parameters = {
        'tmdbId': episode!.tvShowId,
        'title': episode!.tvShowName,
        'season': episode!.season,
        'episode': episode!.number,
      };
    }

    Preferences preferences = Preferences();

    Random random = Random();

    String serverName = await preferences.getServer();

    var extractor;

    if (serverName != 'Random') {
      Server server = servers.firstWhere((server) => server.name == serverName);
      extractor = server.extractor;
    }

    MediaStream? stream;

    while (stream == null && servers.isNotEmpty) {
      int randomIndex = random.nextInt(servers.length);

      if (serverName == 'Random' && extractor == null) {
        Server server = servers[randomIndex];
        extractor = server.extractor;
      }

      stream = await extractor.extract(parameters);

      if (stream!.url == null) {
        if (serverName == 'Random') servers.removeAt(randomIndex);
        stream = null;
      }
    }

    if (!kReleaseMode) print('$serverName: ${stream?.url}');
    return stream!;
  }
}