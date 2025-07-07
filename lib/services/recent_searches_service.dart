import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_names.dart';
import '../enums/media_type.dart';

class RecentSearchesService {
  static final RecentSearchesService _instance = RecentSearchesService._internal();
  factory RecentSearchesService() => _instance;
  RecentSearchesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getFieldName(MediaType mediaType) {
    return mediaType == MediaType.movies ? 'movies' : 'tv_shows';
  }

  Future<List<String>> getRecentSearches(MediaType mediaType) async {
    try {
      final doc = await _firestore
          .collection(DB.recentSearches)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final searches = ((data?[_getFieldName(mediaType)] ?? []) as List<dynamic>)
            .cast<String>();

        // Return in reverse order (most recent first)
        return searches.reversed.toList();
      }
    } catch (e) {
      print("Error getting recent searches: $e");
    }
    return [];
  }

  Future<void> addToRecentSearches(MediaType mediaType, String query) async {
    try {
      final fieldName = _getFieldName(mediaType);
      final searches = await getRecentSearches(mediaType);

      // Remove if already exists to avoid duplicates
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Limit to 20 recent searches
      if (searches.length > 20) {
        searches.removeRange(20, searches.length);
      }

      await _firestore
          .collection(DB.recentSearches)
          .doc(_auth.currentUser!.uid)
          .set({fieldName: searches}, SetOptions(merge: true));
    } catch (e) {
      print("Error adding to recent searches: $e");
      throw e;
    }
  }

  Future<void> removeFromRecentSearches(MediaType mediaType, String query) async {
    try {
      final fieldName = _getFieldName(mediaType);
      final searches = await getRecentSearches(mediaType);

      searches.remove(query);

      await _firestore
          .collection(DB.recentSearches)
          .doc(_auth.currentUser!.uid)
          .set({fieldName: searches}, SetOptions(merge: true));
    } catch (e) {
      print("Error removing from recent searches: $e");
      throw e;
    }
  }

  Future<void> clearRecentSearches(MediaType mediaType) async {
    try {
      final fieldName = _getFieldName(mediaType);

      await _firestore
          .collection(DB.recentSearches)
          .doc(_auth.currentUser!.uid)
          .set({fieldName: []}, SetOptions(merge: true));
    } catch (e) {
      print("Error clearing recent searches: $e");
      throw e;
    }
  }
}