import "package:flutter/material.dart";

class Urls {
  static const String tmdbApiBase = "https://api.themoviedb.org/3";
  static const String searchMovies = "$tmdbApiBase/search/movie";
  static const String searchTvShows = "$tmdbApiBase/search/tv";
  static const String nowPlayingMovies = "$tmdbApiBase/movie/now_playing";
  static const String onTheAirTvShows = "$tmdbApiBase/tv/on_the_air";
  static const String trendingMovies = "$tmdbApiBase/trending/movie/week";
  static const String popularMovies = "$tmdbApiBase/movie/popular";
  static const String popularTvShows = "$tmdbApiBase/tv/popular";
  static const String topRatedMovies = "$tmdbApiBase/movie/top_rated";
  static const String topRatedTvShows = "$tmdbApiBase/tv/top_rated";
  static const String movieGenres = "$tmdbApiBase/genre/movie/list";
  static const String tvShowGenres = "$tmdbApiBase/genre/tv/list";
  static const String discoverMovie = "$tmdbApiBase/discover/movie";
  static const String discoverTvShow = "$tmdbApiBase/discover/tv";

  static const String image45 = "https://image.tmdb.org/t/p/w45";
  static const String image92 = "https://image.tmdb.org/t/p/w92";
  static const String image154 = "https://image.tmdb.org/t/p/w154";
  static const String image185 = "https://image.tmdb.org/t/p/w185";
  static const String image300 = "https://image.tmdb.org/t/p/w300";
  static const String image342 = "https://image.tmdb.org/t/p/w342";
  static const String image500 = "https://image.tmdb.org/t/p/w500";
  static const String image632 = "https://image.tmdb.org/t/p/w632";
  static const String image780 = "https://image.tmdb.org/t/p/w780";
  static const String image1280 = "https://image.tmdb.org/t/p/w1280";
  static const String imageOriginal = "https://image.tmdb.org/t/p/original";

  static const String subdlApiBase = "https://api.subdl.com";
  static const String subdlDownloadBase = "https://dl.subdl.com";
  static const String subtitles = "$subdlApiBase/api/v1/subtitles";

  static const String github = "https://github.com/moses-mbaga/semo";
  static const String mosesGithub = "https://github.com/moses-mbaga";

  static String getMovieDetails(int id) => "$tmdbApiBase/movie/$id";
  static String getTvShowDetails(int id) => "$tmdbApiBase/tv/$id";
  static String getEpisodes(int id, int season) => "$tmdbApiBase/tv/$id/season/$season";
  static String getMovieVideosUrl(int id) => "$tmdbApiBase/movie/$id/videos";
  static String getTvShowVideosUrl(int id) => "$tmdbApiBase/tv/$id/videos";
  static String getMovieStreamUrl(int id) => "https://vidsrc.cc/v2/embed/movie/$id";
  static String getEpisodeStreamUrl(int id, int season, int episode) => "https://vidsrc.cc/v2/embed/tv/$id/$season/$episode";
  static String getMovieCast(int id) => "$tmdbApiBase/movie/$id/credits";
  static String getTvShowCast(int id) => "$tmdbApiBase/tv/$id/aggregate_credits";
  static String getPersonMovies(int id) => "$tmdbApiBase/person/$id/movie_credits";
  static String getPersonTvShows(int id) => "$tmdbApiBase/person/$id/tv_credits";
  static String getMovieRecommendations(int id) => "$tmdbApiBase/movie/$id/recommendations";
  static String getTvShowRecommendations(int id) => "$tmdbApiBase/tv/$id/recommendations";
  static String getMovieSimilar(int id) => "$tmdbApiBase/movie/$id/similar";
  static String getTvShowSimilar(int id) => "$tmdbApiBase/tv/$id/similar";

  static String getBestImageUrl(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= 45) {
      return image45;
    } else if (screenWidth <= 92) {
      return image92;
    } else if (screenWidth <= 154) {
      return image154;
    } else if (screenWidth <= 185) {
      return image185;
    } else if (screenWidth <= 300) {
      return image300;
    } else if (screenWidth <= 342) {
      return image342;
    } else if (screenWidth <= 500) {
      return image500;
    } else if (screenWidth <= 632) {
      return image632;
    } else if (screenWidth <= 780) {
      return image780;
    } else if (screenWidth <= 1280) {
      return image1280;
    } else {
      return imageOriginal;
    }
  }
}