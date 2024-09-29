class Person {
  bool adult;
  int id;
  String name;
  String? profilePath;
  String department;

  Person({
    required this.adult,
    required this.id,
    required this.name,
    required this.profilePath,
    required this.department,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      adult: json['adult'],
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      department: json['known_for_department'],
    );
  }
}