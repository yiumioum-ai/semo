import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/stream.dart';
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/utils/extractors/auto_embed.dart';
import 'package:semo/utils/extractors/kisskh.dart';
import 'package:semo/utils/extractors/movies_api.dart';
import 'package:semo/utils/extractors/rive.dart';

class Extractor {
  model.Movie? movie;
  model.Episode? episode;

  Extractor({
    this.movie,
    this.episode,
  });

  Future<MediaStream> getStream() async {
    List extractors = [
      AutoEmbedExtractor(),
      KissKhExtractor(),
      MoviesApi(),
      Rive(),
    ];

    late Map<String, dynamic> parameters;
    Random random = Random();
    MediaStream? stream;

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

    while (stream == null && extractors.isNotEmpty) {
      int randomIndex = random.nextInt(extractors.length);
      var extractor = extractors[randomIndex];

      stream = await extractor.extract(parameters);

      if (stream!.url == null) {
        extractors.removeAt(randomIndex);
        stream = null;
      }
    }

    if (!kReleaseMode) print('${stream!.extractor}: ${stream.url}');
    return stream!;
  }
}