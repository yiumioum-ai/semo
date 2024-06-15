class SearchResults {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<Movie> movies;

  SearchResults({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.movies,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;
    List<Movie> movies = list.map((i) => Movie.fromJson(i)).toList();

    return SearchResults(
      page: json['page'],
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
      movies: movies,
    );
  }
}

class Movie {
  final bool adult;
  final String backdropPath;
  final List<int> genreIds;
  final int id;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String posterPath;
  final String releaseDate;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;

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
      popularity: json['popularity'].toDouble() ?? 0.0,
      posterPath: json['poster_path'] ?? '',
      releaseDate: json['release_date'],
      title: json['title'],
      video: json['video'],
      voteAverage: json['vote_average'].toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
    );
  }
}
