import "dart:io";

class MediaStream {
  MediaStream({
    this.url,
    this.headers,
    this.subtitleFiles,
  });

  final String? url;
  final Map<String, String>? headers;
  List<File>? subtitleFiles;
}