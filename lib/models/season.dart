import "package:semo/models/episode.dart";

class Season {
  Season({
    required this.id,
    required this.number,
    required this.name,
    required this.airDate,
    this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
      id: json["id"] ?? 0,
      number: json["season_number"] ?? 0,
      name: json["name"] ?? "",
      airDate: json["air_date"],
    );

  final int id;
  final int number;
  final String name;
  final String? airDate;
  List<Episode>? episodes;
}