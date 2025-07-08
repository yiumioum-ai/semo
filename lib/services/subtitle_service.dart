import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:archive/archive.dart";
import "package:http/http.dart" as http;
import "package:logger/logger.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:semo/utils/secrets.dart";
import "package:semo/utils/urls.dart";

class SubtitleService {
  factory SubtitleService() => _instance;
  SubtitleService._internal();

  static final SubtitleService _instance = SubtitleService._internal();

  final Logger _logger = Logger();

  Future<List<File>> getMovieSubtitles(int tmdbId) => _getSubtitles(tmdbId: tmdbId);

  Future<List<File>> getTvShowSubtitles(int tmdbId, int seasonNumber, int episodeNumber) => _getSubtitles(
    tmdbId: tmdbId,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
  );

  Future<List<File>> _getSubtitles({required int tmdbId, int? seasonNumber, int? episodeNumber}) async {
    try {
      final List<File> srtFiles = <File>[];

      final Map<String, dynamic> parameters = <String, dynamic>{
        "api_key": Secrets.subdlApiKey,
        "tmdb_id": "$tmdbId",
        "languages": "EN",
        "subs_per_page": "5",
      };

      if (seasonNumber != null) {
        parameters["season_number"] = "$seasonNumber";
      }
      if (episodeNumber != null) {
        parameters["episode_number"] = "$episodeNumber";
      }

      final Uri uri = Uri.parse(Urls.subtitles).replace(queryParameters: parameters);
      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic subtitlesData = jsonDecode(response.body);
        final List<dynamic> subtitles = subtitlesData["subtitles"] as List<dynamic>;

        final Directory directory = await getTemporaryDirectory();
        final String destinationDirectory = directory.path;

        for (final dynamic subtitle in subtitles) {
          final String zipUrl = subtitle["url"] as String;
          final String fullZipUrl = Urls.subdlDownloadBase + zipUrl;

          final http.Response zipResponse = await http.get(Uri.parse(fullZipUrl));

          if (zipResponse.statusCode == 200) {
            final Uint8List bytes = zipResponse.bodyBytes;
            final Archive archive = ZipDecoder().decodeBytes(bytes);

            for (final dynamic file in archive) {
              if (file.isFile) {
                final String fileName = file.name;
                final String extension = path.extension(fileName);

                if (extension == ".srt") {
                  final List<int> data = file.content as List<int>;
                  final File srtFile = File("$destinationDirectory/$fileName");
                  await srtFile.writeAsBytes(data);
                  srtFiles.add(srtFile);
                }
              }
            }
          }
        }
      }

      return srtFiles;
    } catch (e, s) {
      _logger.e("Error getting subtitles", error: e, stackTrace: s);
      rethrow;
    }
  }
}