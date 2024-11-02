class MediaStream {
  String extractor;
  String? url;
  Map<String, String>? headers;

  MediaStream({
    required this.extractor,
    this.url,
    this.headers,
  });
}
