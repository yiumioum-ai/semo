class MediaStream {
  MediaStream({
    this.url = "",
    this.headers = const <String, String>{},
  });

  final String url;
  final Map<String, String> headers;
}