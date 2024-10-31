import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class AutoEmbedExtractor {
  final String baseUrl = 'https://autoembed.cc';

  Future<String?> extract(Map<String, dynamic> parameters) async {
    try {
      int tmdbId = parameters['tmdbId'];
      int? season = parameters['season'];
      int? episode = parameters['episode'];

      String serverUrl = season == null && episode == null
          ? 'https://$baseUrl/embed/oplayer.php?id=$tmdbId'
          : 'https://$baseUrl/embed/oplayer.php?id=$tmdbId&s=$season&e=$episode';

      String? streamUrl = await fetchMultiExtractor(serverUrl);

      return streamUrl;
    } catch (err) {
      print('Error fetching stream: $err');
      return null;
    }
  }

  Future<String?> fetchMultiExtractor(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);

        String? scriptContent = document
            .querySelectorAll('script')
            .map((script) => script.innerHtml)
            .firstWhere((content) => content.contains('Playerjs'), orElse: () => '');

        if (scriptContent.isNotEmpty) {
          return extractStreamFromScript(scriptContent);
        } else {
          print('No Playerjs script found in the HTML');
          return null;
        }
      } else {
        print('Failed to fetch HTML. Status code: ${response.statusCode}');
        return null;
      }
    } catch (err) {
      print('Error in fetchMultiExtractor: $err');
      return null;
    }
  }

  String? extractStreamFromScript(String scriptContent) {
    RegExp regex = RegExp(r'"title":\s*"([^"]+)",\s*"file":\s*"(https:\/\/[^"]+)"');
    Iterable<RegExpMatch> matches = regex.allMatches(scriptContent);

    for (var match in matches) {
      String language = match.group(1) ?? '';
      String url = match.group(2) ?? '';

      if (language == 'English') return url;
    }

    return null;
  }
}