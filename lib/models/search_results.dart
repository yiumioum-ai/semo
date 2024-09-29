import 'package:semo/models/movie.dart';
import 'package:semo/models/tv_show.dart';
import 'package:semo/utils/enums.dart';

class SearchResults {
  int page;
  int totalPages;
  int totalResults;
  List<Movie>? movies;
  List<TvShow>? tvShows;

  SearchResults({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    this.movies,
    this.tvShows,
  });

  factory SearchResults.fromJson(PageType pageType, Map<String, dynamic> json) {
    List results = json['results'] as List;
    List<Movie>? movies;
    List<TvShow>? tvShows;

    if (pageType == PageType.movies) {
       movies = results.map((json) => Movie.fromJson(json)).toList();
    } else {
      tvShows = results.map((json) => TvShow.fromJson(json)).toList();
    }

    return SearchResults(
      page: json['page'],
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
      movies: movies,
      tvShows: tvShows,
    );
  }
}
