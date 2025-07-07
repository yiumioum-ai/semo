import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:logger/logger.dart";
import "package:semo/utils/db_names.dart";

class FavoritesService {
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static final FavoritesService _instance = FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  DocumentReference<Map<String, dynamic>> _getDocReference() {
    try {
      return _firestore
          .collection(DB.favorites)
          .doc(_auth.currentUser?.uid);
    } catch (e, s) {
      _logger.e("Error getting favorites' document reference", error: e, stackTrace: s);
    }

    throw Exception("Failed to get favorites' document reference");
  }

  Future<Map<String, dynamic>> _getFavorites() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _getDocReference().get();

      if (doc.exists) {
        return doc.data() ?? <String, dynamic>{};
      }
    } catch (e, s) {
      _logger.e("Error getting favorites", error: e, stackTrace: s);
    }

    return <String, dynamic>{};
  }

  Future<List<int>> getFavoriteMovies() async {
    final Map<String, dynamic> favorites = await _getFavorites();

    try {
      return ((favorites["movies"] ?? <dynamic>[]) as List<dynamic>).cast<int>();
    } catch (e, s) {
      _logger.e("Error getting favorite movies", error: e, stackTrace: s);
    }

    return <int>[];
  }

  Future<List<int>> getFavoriteTvShows() async {
    final Map<String, dynamic> favorites = await _getFavorites();

    try {
      return ((favorites["tv_shows"] ?? <dynamic>[]) as List<dynamic>).cast<int>();
    } catch (e, s) {
      _logger.e("Error getting favorite TV shows", error: e, stackTrace: s);
    }

    return <int>[];
  }

  Future<void> addMovieToFavorites(int movieId) async {
    final List<int> favorites = await getFavoriteMovies();

    if (!favorites.contains(movieId)) {
      favorites.add(movieId);
      try {
        await _getDocReference().set(<String, dynamic>{"movies": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error adding movie to favorites", error: e, stackTrace: s);
      }
    }
  }

  Future<void> addTvShowToFavorites(int tvShowId) async {
    final List<int> favorites = await getFavoriteTvShows();

    if (!favorites.contains(tvShowId)) {
      favorites.add(tvShowId);
      try {
        await _getDocReference().set(<String, dynamic>{"tv_shows": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error adding TV show to favorites", error: e, stackTrace: s);
      }
    }
  }

  Future<void> removeMovieFromFavorites(int movieId) async {
    final List<int> favorites = await getFavoriteMovies();

    if (favorites.contains(movieId)) {
      favorites.remove(movieId);
      try {
        await _getDocReference().set(<String, dynamic>{"movies": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error removing movie from favorites", error: e, stackTrace: s);
      }
    }
  }

  Future<void> removeTvShowFromFavorites(int tvShowId) async {
    final List<int> favorites = await getFavoriteTvShows();

    if (favorites.contains(tvShowId)) {
      favorites.remove(tvShowId);
      try {
        await _getDocReference().set(<String, dynamic>{"tv_shows": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error removing TV show from favorites", error: e, stackTrace: s);
      }
    }
  }
}