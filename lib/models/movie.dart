import 'package:semo/models/person.dart';

class Movie {
  bool adult;
  String backdropPath;
  List<int> genreIds;
  int id;
  String originalLanguage;
  String originalTitle;
  String overview;
  double popularity;
  String posterPath;
  String releaseDate;
  String title;
  bool video;
  double voteAverage;
  int voteCount;
  String? trailerUrl;
  String? streamUrl;
  List<Person>? cast;
  List<Movie>? recommendations;
  List<Movie>? similar;

  Movie({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    this.trailerUrl,
    this.streamUrl,
    this.cast,
    this.recommendations,
    this.similar,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      adult: json['adult'],
      backdropPath: json['backdrop_path'] ?? '',
      genreIds: List<int>.from(json['genre_ids']),
      id: json['id'],
      originalLanguage: json['original_language'],
      originalTitle: json['original_title'],
      overview: json['overview'],
      popularity: double.parse((json['popularity'].toDouble() ?? 0.0).toStringAsFixed(1)),
      posterPath: json['poster_path'] ?? '',
      releaseDate: json['release_date'],
      title: json['title'],
      video: json['video'],
      voteAverage: double.parse((json['vote_average'].toDouble() ?? 0.0).toStringAsFixed(1)),
      voteCount: json['vote_count'] ?? 0,
    );
  }
}