import 'dart:math';

import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/utils/extractors/autoembed.dart';

class Extractor {
  model.Movie? movie;
  model.Episode? episode;

  Extractor({
    this.movie,
    this.episode,
  });

  Future<String?> getStream() async {
    List extractors = [
      AutoEmbedExtractor(),
    ];

    Random random = Random();
    int randomIndex = random.nextInt(extractors.length);
    var extractor = extractors[randomIndex];

    late Map<String, dynamic> parameters;
    String? streamUrl;

    if (movie != null) {
      parameters = {
        'tmdbId': movie!.id,
      };
      streamUrl = await extractor.extract(parameters);
    } else if (episode != null) {
      parameters = {
        'tmdbId': episode!.tvShowId,
        'season': episode!.season,
        'episode': episode!.number,
      };
      streamUrl = await extractor.extract(parameters);
    }

    return streamUrl;
  }
}