class Person {
  const Person({
    required this.adult,
    required this.id,
    required this.name,
    required this.profilePath,
    required this.department,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
      adult: json["adult"] ?? false,
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      profilePath: json["profile_path"],
      department: json["known_for_department"] ?? "",
    );

  final bool adult;
  final int id;
  final String name;
  final String? profilePath;
  final String department;
}