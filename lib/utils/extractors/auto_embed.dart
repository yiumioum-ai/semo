import 'package:http/http.dart' as http;
import 'package:semo/models/stream.dart';

class AutoEmbedExtractor {
  final String baseUrl = 'autoembed.cc';

  Future<MediaStream> extract(Map<String, dynamic> parameters) async {
    try {
      int tmdbId = parameters['tmdbId'];
      int? season = parameters['season'];
      int? episode = parameters['episode'];

      String serverUrl = season == null && episode == null
          ? 'https://$baseUrl/embed/oplayer.php?id=$tmdbId'
          : 'https://$baseUrl/embed/oplayer.php?id=$tmdbId&s=$season&e=$episode';

      String? streamUrl = await findStream(serverUrl);

      return MediaStream(extractor: 'AutoEmbed', url: streamUrl);
    } catch (err) {
      print('AutoEmbed - Error fetching stream: $err');
      return MediaStream(extractor: 'AutoEmbed');
    }
  }

  Future<String?> findStream(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return extractStreamFromMultiScript(response.body);
      } else {
        print('AutoEmbed - Failed to fetch HTML. Status code: ${response.statusCode}');
        return null;
      }
    } catch (err) {
      print('AutoEmbed - Error in findStream: $err');
      return null;
    }
  }

  String? extractStreamFromMultiScript(String scriptContent) {
    RegExp regex = RegExp(r'"title":\s*"([^"]+)",\s*"file":\s*"(https:\/\/[^"]+)"');
    Iterable<RegExpMatch> matches = regex.allMatches(scriptContent);

    for (var match in matches) {
      String language = match.group(1) ?? '';
      String? url = match.group(2);

      if (language == 'English') return url;
    }

    return null;
  }
}