class Genre {
  const Genre({
    required this.id,
    required this.name,
    this.backdropPath,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
    );

  final int id;
  final String name;
  final String? backdropPath;
}