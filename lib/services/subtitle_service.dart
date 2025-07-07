import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/secrets.dart';
import '../utils/urls.dart';

class SubtitleService {
  static final SubtitleService _instance = SubtitleService._internal();
  factory SubtitleService() => _instance;
  SubtitleService._internal();

  Future<List<File>> getMovieSubtitles(int tmdbId) async {
    return await _getSubtitles(tmdbId: tmdbId);
  }

  Future<List<File>> getTvShowSubtitles(int tmdbId, int seasonNumber, int episodeNumber) async {
    return await _getSubtitles(
      tmdbId: tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<List<File>> _getSubtitles({required int tmdbId, int? seasonNumber, int? episodeNumber}) async {
    final srtFiles = <File>[];

    try {
      final parameters = <String, dynamic>{
        'api_key': Secrets.subdlApiKey,
        'tmdb_id': '$tmdbId',
        'languages': 'EN',
        'subs_per_page': '5',
      };

      if (seasonNumber != null) {
        parameters['season_number'] = '$seasonNumber';
      }
      if (episodeNumber != null) {
        parameters['episode_number'] = '$episodeNumber';
      }

      final uri = Uri.parse(Urls.subtitles).replace(queryParameters: parameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final subtitlesData = jsonDecode(response.body);
        final subtitles = subtitlesData['subtitles'] as List;

        final directory = await getTemporaryDirectory();
        final destinationDirectory = directory.path;

        for (final subtitle in subtitles) {
          final zipUrl = subtitle['url'] as String;
          final fullZipUrl = Urls.subdlDownloadBase + zipUrl;

          final zipResponse = await http.get(Uri.parse(fullZipUrl));

          if (zipResponse.statusCode == 200) {
            final bytes = zipResponse.bodyBytes;
            final archive = ZipDecoder().decodeBytes(bytes);

            for (final file in archive) {
              if (file.isFile) {
                final fileName = file.name;
                final extension = path.extension(fileName);

                if (extension == '.srt') {
                  final data = file.content as List<int>;
                  final srtFile = File('$destinationDirectory/$fileName');
                  await srtFile.writeAsBytes(data);
                  srtFiles.add(srtFile);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting subtitles: $e');
    }

    return srtFiles;
  }
}