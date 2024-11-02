import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:semo/models/stream.dart';
import 'package:semo/utils/urls.dart';

class KissKhExtractor {
  final String baseUrl = 'https://kisskh.co';

  Future<List<Map<String, dynamic>>> search(String query) async {
    final searchUrl = '$baseUrl/api/DramaList/Search?q=$query&type=0';
    final response = await http.get(
      Uri.parse(searchUrl),
      headers: Urls.puppetHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((item) => {
        'id': item['id'],
        'title': item['title'],
        'link': '$baseUrl/api/DramaList/Drama/${item['id']}?isq=false',
      }).toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<int?> getMediaId(int searchId, int episodeNumber) async {
    final url = '$baseUrl/api/DramaList/Drama/$searchId?isq=false';
    final response = await http.get(
      Uri.parse(url),
      headers: Urls.puppetHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List episodes = data['episodes'];

      for (var episode in episodes) {
        if (episode['number'] == episodeNumber) {
          return episode['id'];
        }
      }
    } else {
      throw Exception('Failed to load media id');
    }

    return null;
  }

  Future<String?> getStreamUrl(int id) async {
    final streamUrl = '$baseUrl/api/DramaList/Episode/$id.png?err=false&ts=&time=';

    final streamResponse = await http.get(Uri.parse(streamUrl));
    final videoLink = json.decode(streamResponse.body)['Video'];

    return videoLink;
  }

  Future<MediaStream> extract(Map<String, dynamic> parameters) async {
    String searchQuery = parameters['title'];
    int? season = parameters['season'];
    int episode = parameters['episode'] ?? 1;

    if (season != null) {
      searchQuery += ' - Season $season';
    }

    try {
      print("Searching for media: $searchQuery");
      final List<Map<String, dynamic>?> searchResults = await search(searchQuery);

      final matchedPost = searchResults.firstWhere((post) {
        if (post != null) {
          return post['title'].toLowerCase() == searchQuery.toLowerCase();
        } else {
          return false;
        }
      });

      if (matchedPost == null) {
        print("No matching post found for '$searchQuery'");
        return MediaStream(extractor: 'KissKh');
      }

      print("Found match: ${matchedPost['title']}");

      print("Extracting media id for: ${matchedPost['title']}");
      final int? mediaId = await getMediaId(matchedPost['id'], episode);

      if (mediaId == null) {
        print("No media id found for '$searchQuery'");
        return MediaStream(extractor: 'KissKh');
      }

      print("Extracting streams for: ${matchedPost['title']}");
      String? streamUrl = await getStreamUrl(mediaId);

      if (streamUrl != null && streamUrl.isNotEmpty) {
        return MediaStream(extractor: 'KissKh', url: streamUrl);
      } else {
        print("KissKh - No streams found for '${matchedPost['title']}'");
      }
    } catch (e) {
      print("KissKh - Error during search and extraction: $e");
    }

    return MediaStream(extractor: 'KissKh');
  }
}