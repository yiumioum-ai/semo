import 'package:semo/models/movie.dart';
import 'package:semo/models/person.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/enums/media_type.dart';

class SearchResults {
  int page;
  int totalPages;
  int totalResults;
  List<Movie>? movies;
  List<TvShow>? tvShows;
  List<Person>? cast;

  SearchResults({
    this.page = 0,
    this.totalPages = 0,
    this.totalResults = 0,
    this.movies,
    this.tvShows,
    this.cast,
  });

  factory SearchResults.fromJson(MediaType? mediaType, Map<String, dynamic> json) {
    List<Movie>? movies;
    List<TvShow>? tvShows;
    List<Person>? cast;

    if (mediaType != null) {
      List results = json['results'] as List;
      if (mediaType == MediaType.movies) {
        movies = results.map((json) => Movie.fromJson(json)).toList();
      } else {
        tvShows = results.map((json) => TvShow.fromJson(json)).toList();
      }
    } else {
      List results = json['cast'] as List;
      List<Person> allCast = results.map((json) => Person.fromJson(json)).toList();
      cast = allCast.where((person) => person.department == 'Acting').toList();
    }

    return SearchResults(
      page: json['page'],
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
      movies: movies,
      tvShows: tvShows,
      cast: cast,
    );
  }
}
