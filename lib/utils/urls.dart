class Urls {
  static const String movieSearch = 'https://api.themoviedb.org/3/search/movie';
  static const String imageBase_w45 = 'https://image.tmdb.org/t/p/w45';
  static const String imageBase_w92 = 'https://image.tmdb.org/t/p/w92';
  static const String imageBase_w154 = 'https://image.tmdb.org/t/p/w154';
  static const String imageBase_w185 = 'https://image.tmdb.org/t/p/w185';
  static const String imageBase_w300 = 'https://image.tmdb.org/t/p/w300';
  static const String imageBase_w342 = 'https://image.tmdb.org/t/p/w342';
  static const String imageBase_w500 = 'https://image.tmdb.org/t/p/w500';
  static const String imageBase_w632 = 'https://image.tmdb.org/t/p/w632';
  static const String imageBase_w780 = 'https://image.tmdb.org/t/p/w780';
  static const String imageBase_w1280 = 'https://image.tmdb.org/t/p/w1280';
  static const String imageBase_original = 'https://image.tmdb.org/t/p/original';

  static createUri({required String url, Map<String, dynamic>? queryParameters}) {
    var isHttp = false;
    if (url.startsWith('https://') || (isHttp = url.startsWith('http://'))) {
      var authority = url.substring((isHttp ? 'http://' : 'https://').length);
      String path;
      final index = authority.indexOf('/');

      if (-1 == index) {
        path = '';
      } else {
        path = authority.substring(index);
        authority = authority.substring(0, authority.length - path.length);
      }

      if (isHttp) {
        return Uri.http(authority, path, queryParameters);
      } else {
        return Uri.https(authority, path, queryParameters);
      }
    } else if (url.startsWith('localhost')) {
      return createUri(url: 'http://$url', queryParameters: queryParameters);
    }
    throw Exception('Unsupported scheme');
  }
}