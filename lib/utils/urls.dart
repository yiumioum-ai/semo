import 'package:flutter/material.dart';

class Urls {
  static const String search = 'https://api.themoviedb.org/3/search';
  static const String imageBase_w45 = 'https://image.tmdb.org/t/p/w45';
  static const String imageBase_w92 = 'https://image.tmdb.org/t/p/w92';
  static const String imageBase_w154 = 'https://image.tmdb.org/t/p/w154';
  static const String imageBase_w185 = 'https://image.tmdb.org/t/p/w185';
  static const String imageBase_w300 = 'https://image.tmdb.org/t/p/w300';
  static const String imageBase_w342 = 'https://image.tmdb.org/t/p/w342';
  static const String imageBase_w500 = 'https://image.tmdb.org/t/p/w500';
  static const String imageBase_w632 = 'https://image.tmdb.org/t/p/w632';
  static const String imageBase_w780 = 'https://image.tmdb.org/t/p/w780';
  static const String imageBase_w1280 = 'https://image.tmdb.org/t/p/w1280';
  static const String imageBase_original = 'https://image.tmdb.org/t/p/original';

  static String getMovieVideosUrl(int id) => 'https://api.themoviedb.org/3/movie/$id/videos';
  static String getTvShowVideosUrl(int id) => 'https://api.themoviedb.org/3/tv/$id/videos';
  static String getMovieStreamUrl(int id) => 'https://dev.examnet.net/semo/?id=$id&type=movie';
  static String getEpisodeStreamUrl(int id, int season, int episode) => 'https://dev.examnet.net/semo/?id=$id&type=tv&season=$season&episode=$episode';
  static String getMovieCast(int id) => 'https://api.themoviedb.org/3/movie/$id/credits';
  static String getTvShowCast(int id) => 'https://api.themoviedb.org/3/tv/$id/aggregate_credits';
  static String getMovieRecommendations(int id) => 'https://api.themoviedb.org/3/movie/$id/recommendations';
  static String getTvShowRecommendations(int id) => 'https://api.themoviedb.org/3/tv/$id/recommendations';
  static String getMovieSimilar(int id) => 'https://api.themoviedb.org/3/movie/$id/similar';
  static String getTvShowSimilar(int id) => 'https://api.themoviedb.org/3/tv/$id/similar';

  static String getBestImageUrl(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= 45) {
      return imageBase_w45;
    } else if (screenWidth <= 92) {
      return imageBase_w92;
    } else if (screenWidth <= 154) {
      return imageBase_w154;
    } else if (screenWidth <= 185) {
      return imageBase_w185;
    } else if (screenWidth <= 300) {
      return imageBase_w300;
    } else if (screenWidth <= 342) {
      return imageBase_w342;
    } else if (screenWidth <= 500) {
      return imageBase_w500;
    } else if (screenWidth <= 632) {
      return imageBase_w632;
    } else if (screenWidth <= 780) {
      return imageBase_w780;
    } else if (screenWidth <= 1280) {
      return imageBase_w1280;
    } else {
      return imageBase_original;
    }
  }
}