import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_names.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<int>> getFavoriteMovies() async {
    try {
      final doc = await _firestore
          .collection(DB.favorites)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return ((data?['movies'] ?? []) as List<dynamic>).cast<int>();
      }
    } catch (e) {
      print("Error getting favorite movies: $e");
    }
    return [];
  }

  Future<List<int>> getFavoriteTvShows() async {
    try {
      final doc = await _firestore
          .collection(DB.favorites)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return ((data?['tv_shows'] ?? []) as List<dynamic>).cast<int>();
      }
    } catch (e) {
      print("Error getting favorite TV shows: $e");
    }
    return [];
  }

  Future<void> addMovieToFavorites(int movieId) async {
    final favorites = await getFavoriteMovies();
    if (!favorites.contains(movieId)) {
      favorites.add(movieId);
      await _firestore
          .collection(DB.favorites)
          .doc(_auth.currentUser!.uid)
          .set({'movies': favorites}, SetOptions(merge: true));
    }
  }

  Future<void> addTvShowToFavorites(int tvShowId) async {
    final favorites = await getFavoriteTvShows();
    if (!favorites.contains(tvShowId)) {
      favorites.add(tvShowId);
      await _firestore
          .collection(DB.favorites)
          .doc(_auth.currentUser!.uid)
          .set({'tv_shows': favorites}, SetOptions(merge: true));
    }
  }

  Future<void> removeMovieFromFavorites(int movieId) async {
    final favorites = await getFavoriteMovies();
    favorites.remove(movieId);
    await _firestore
        .collection(DB.favorites)
        .doc(_auth.currentUser!.uid)
        .set({'movies': favorites}, SetOptions(merge: true));
  }

  Future<void> removeTvShowFromFavorites(int tvShowId) async {
    final favorites = await getFavoriteTvShows();
    favorites.remove(tvShowId);
    await _firestore
        .collection(DB.favorites)
        .doc(_auth.currentUser!.uid)
        .set({'tv_shows': favorites}, SetOptions(merge: true));
  }
}