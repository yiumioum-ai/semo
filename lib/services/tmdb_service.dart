import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../models/person.dart';
import '../models/search_results.dart';
import '../utils/api_keys.dart';
import '../utils/enums.dart';
import '../utils/urls.dart';

class TMDBService {
  static final TMDBService _instance = TMDBService._internal();
  factory TMDBService() => _instance;
  TMDBService._internal();

  final Map<String, String> _headers = {
    HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
  };

  Map<String, String> getHeaders() {
    return _headers;
  }

  // Movie Methods
  Future<List<Movie>> getNowPlayingMovies() async {
    try {
      final response = await http.get(
        Uri.parse(Urls.nowPlayingMovies),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body)['results'] as List;
        return data.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting now playing movies: $e');
    }
    return [];
  }

  Future<SearchResults> getTrendingMovies(int page) async {
    return _getMovies(Urls.trendingMovies, page);
  }

  Future<SearchResults> getPopularMovies(int page) async {
    return _getMovies(Urls.popularMovies, page);
  }

  Future<SearchResults> getTopRatedMovies(int page) async {
    return _getMovies(Urls.topRatedMovies, page);
  }

  Future<SearchResults> discoverMovies(
      int page, {
        Map<String, String>? parameters,
      }) async {
    return _getMovies(Urls.discoverMovie, page, parameters: parameters);
  }

  Future<SearchResults> _getMovies(
      String url,
      int page, {
        Map<String, String>? parameters,
      }) async {
    try {
      final queryParams = {
        'page': '$page',
        ...?parameters,
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return SearchResults.fromJson(
          PageType.movies,
          json.decode(response.body),
        );
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting movies from $url: $e');
    }
    return SearchResults(page: 0, totalPages: 0, totalResults: 0);
  }

  Future<Movie?> getMovieDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse(Urls.getMovieDetails(id)),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return Movie.fromJson(json.decode(response.body));
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting movie details for $id: $e');
    }
    return null;
  }

  Future<List<Genre>> getMovieGenres() async {
    try {
      final response = await http.get(
        Uri.parse(Urls.movieGenres),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body)['genres'] as List;
        return data.map((json) => Genre.fromJson(json)).toList();
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting movie genres: $e');
    }
    return [];
  }

  // TV Show Methods
  Future<List<TvShow>> getOnTheAirTvShows() async {
    try {
      final response = await http.get(
        Uri.parse(Urls.onTheAirTvShows),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body)['results'] as List;
        return data.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting on the air TV shows: $e');
    }
    return [];
  }

  Future<SearchResults> getPopularTvShows(int page) async {
    return _getTvShows(Urls.popularTvShows, page);
  }

  Future<SearchResults> getTopRatedTvShows(int page) async {
    return _getTvShows(Urls.topRatedTvShows, page);
  }

  Future<SearchResults> discoverTvShows(
      int page, {
        Map<String, String>? parameters,
      }) async {
    return _getTvShows(Urls.discoverTvShow, page, parameters: parameters);
  }

  Future<SearchResults> _getTvShows(
      String url,
      int page, {
        Map<String, String>? parameters,
      }) async {
    try {
      final queryParams = {
        'page': '$page',
        ...?parameters,
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return SearchResults.fromJson(
          PageType.tv_shows,
          json.decode(response.body),
        );
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting TV shows from $url: $e');
    }
    return SearchResults(page: 0, totalPages: 0, totalResults: 0);
  }

  Future<TvShow?> getTvShowDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse(Urls.getTvShowDetails(id)),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return TvShow.fromJson(json.decode(response.body));
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting TV show details for $id: $e');
    }
    return null;
  }

  Future<List<Genre>> getTvShowGenres() async {
    try {
      final response = await http.get(
        Uri.parse(Urls.tvShowGenres),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body)['genres'] as List;
        return data.map((json) => Genre.fromJson(json)).toList();
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting TV show genres: $e');
    }
    return [];
  }

  // Common methods for both movies and TV shows
  Future<String?> getTrailerUrl(int id, {bool isMovie = true}) async {
    try {
      final url = isMovie
          ? Urls.getMovieVideosUrl(id)
          : Urls.getTvShowVideosUrl(id);

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final videos = json.decode(response.body)['results'] as List;
        final youtubeVideos = videos.where((video) {
          return video['site'] == 'YouTube' &&
              video['type'] == 'Trailer' &&
              video['official'] == true;
        }).toList();

        if (youtubeVideos.isNotEmpty) {
          youtubeVideos.sort((a, b) => b['size'].compareTo(a['size']));
          final youtubeId = youtubeVideos[0]['key'] ?? '';
          return 'https://www.youtube.com/watch?v=$youtubeId';
        }
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting trailer: $e');
    }
    return null;
  }

  Future<int?> getMovieDuration(int id) async {
    try {
      final response = await http.get(
        Uri.parse(Urls.getMovieDetails(id)),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final details = json.decode(response.body) as Map<String, dynamic>;
        return details['runtime'] as int?;
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting movie duration: $e');
    }
    return null;
  }

  Future<List<Person>> getCast(int id, {bool isMovie = true}) async {
    try {
      final url = isMovie
          ? Urls.getMovieCast(id)
          : Urls.getTvShowCast(id);

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body)['cast'] as List;
        final allCast = data.map((json) => Person.fromJson(json)).toList();
        return allCast.where((person) => person.department == 'Acting').toList();
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting cast: $e');
    }
    return [];
  }

  Future<SearchResults> getRecommendations(
      int id,
      int page,
      PageType pageType,
      ) async {
    final url = pageType == PageType.movies
        ? Urls.getMovieRecommendations(id)
        : Urls.getTvShowRecommendations(id);

    return pageType == PageType.movies
        ? _getMovies(url, page)
        : _getTvShows(url, page);
  }

  Future<SearchResults> getSimilar(
      int id,
      int page,
      PageType pageType,
      ) async {
    final url = pageType == PageType.movies
        ? Urls.getMovieSimilar(id)
        : Urls.getTvShowSimilar(id);

    return pageType == PageType.movies
        ? _getMovies(url, page)
        : _getTvShows(url, page);
  }

  Future<List<Season>> getTvShowSeasons(int id) async {
    try {
      final response = await http.get(
        Uri.parse(Urls.getTvShowDetails(id)),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final seasonsData = (json.decode(response.body)['seasons'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        final seasons = <Season>[];
        for (final seasonData in seasonsData) {
          final season = Season.fromJson(seasonData);
          if (season.number > 0 && season.airDate != null) {
            seasons.add(season);
          }
        }
        return seasons;
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting TV show seasons: $e');
    }
    return [];
  }

  Future<List<Episode>> getEpisodes(int showId, int seasonNumber, String showName) async {
    try {
      final response = await http.get(
        Uri.parse(Urls.getEpisodes(showId, seasonNumber)),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final episodesData = json.decode(response.body)['episodes'] as List;
        final episodes = <Episode>[];

        for (var episodeData in episodesData) {
          episodeData['show_name'] = showName;
          final episode = Episode.fromJson(episodeData);
          if (episode.airDate != null) {
            episodes.add(episode);
          }
        }
        return episodes;
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting episodes: $e');
    }
    return [];
  }

  // Genre backdrop helper
  Future<String> getGenreBackdrop(Genre genre, {bool isMovie = true}) async {
    if (genre.backdropPath != null) {
      return genre.backdropPath!;
    }

    try {
      final result = isMovie
          ? await discoverMovies(1, parameters: {'with_genres': '${genre.id}'})
          : await discoverTvShows(1, parameters: {'with_genres': '${genre.id}'});

      if ((isMovie ? result.movies : result.tvShows) != null &&
          (isMovie ? result.movies!.isNotEmpty : result.tvShows!.isNotEmpty)) {
        final random = Random();
        final items = isMovie ? result.movies! : result.tvShows!;
        final randomIndex = random.nextInt(items.length);
        final backdropPath = isMovie
            ? (items[randomIndex] as Movie).backdropPath
            : (items[randomIndex] as TvShow).backdropPath;

        // Cache the backdrop path for future use
        genre.backdropPath = backdropPath;
        return backdropPath;
      }
    } catch (e) {
      if (!kReleaseMode) print('Error getting genre backdrop: $e');
    }

    return '';
  }

  Future<SearchResults> searchMovies(String query, int page) async {
    try {
      final queryParams = {
        'query': query,
        'include_adult': 'false',
        'page': '$page',
      };

      final uri = Uri.parse(Urls.searchMovies).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return SearchResults.fromJson(
          PageType.movies,
          json.decode(response.body),
        );
      }
    } catch (e) {
      if (!kReleaseMode) print('Error searching movies: $e');
    }
    return SearchResults(page: 0, totalPages: 0, totalResults: 0);
  }

  Future<SearchResults> searchTvShows(String query, int page) async {
    try {
      final queryParams = {
        'query': query,
        'include_adult': 'false',
        'page': '$page',
      };

      final uri = Uri.parse(Urls.searchTvShows).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return SearchResults.fromJson(
          PageType.tv_shows,
          json.decode(response.body),
        );
      }
    } catch (e) {
      if (!kReleaseMode) print('Error searching TV shows: $e');
    }
    return SearchResults(page: 0, totalPages: 0, totalResults: 0);
  }
}