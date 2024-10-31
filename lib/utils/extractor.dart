import 'dart:math';

import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/utils/extractors/autoembed.dart';
import 'package:semo/utils/extractors/kisskh.dart';

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
      KissKhExtractor(),
    ];

    Random random = Random();
    int randomIndex = random.nextInt(extractors.length);
    var extractor = extractors[randomIndex];

    late Map<String, dynamic> parameters;
    String? streamUrl;

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

    streamUrl = await extractor.extract(parameters);

    print('Stream URL: $streamUrl');
    return streamUrl;
  }
}