class MediaStream {
  const MediaStream({
    this.url,
    this.headers,
  });

  final String? url;
  final Map<String, String>? headers;
}