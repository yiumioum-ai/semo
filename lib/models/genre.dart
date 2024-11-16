class Genre {
  int id;
  String name;
  String? backdropPath;

  Genre({
    required this.id,
    required this.name,
    this.backdropPath,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'],
      name: json['name'],
    );
  }
}