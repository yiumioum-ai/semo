class Genre {
  Genre({
    required this.id,
    required this.name,
    this.backdropPath,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json["id"] ?? 0,
    name: json["name"] ?? "",
    backdropPath: json["backdrop_path"],
  );

  final int id;
  final String name;
  String? backdropPath;
}