import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:logger/logger.dart";
import "package:semo/utils/db_names.dart";
import "package:semo/enums/media_type.dart";

class RecentSearchesService {
  factory RecentSearchesService() => _instance;
  RecentSearchesService._internal();

  static final RecentSearchesService _instance = RecentSearchesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String _getFieldName(MediaType mediaType) => mediaType == MediaType.movies ? "movies" : "tv_shows";

  DocumentReference<Map<String, dynamic>> _getDocReference() {
    if (_auth.currentUser == null) {
      throw Exception("User isn't authenticated");
    }

    try {
      return _firestore
          .collection(DB.recentSearches)
          .doc(_auth.currentUser?.uid);
    } catch (e, s) {
      _logger.e("Error getting recent searches document reference", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<String>> getRecentSearches(MediaType mediaType) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _getDocReference().get();

      if (!doc.exists) {
        throw Exception("Recent searches doc not found");
      }

      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
      final String fieldName = _getFieldName(mediaType);
      final List<String> searches = ((data[fieldName] ?? <dynamic>[]) as List<dynamic>).cast<String>();

      // Return in reverse order (most recent first)
      return searches.reversed.toList();
    } catch (e, s) {
      _logger.e("Error getting recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> add(MediaType mediaType, String query) async {
    final String fieldName = _getFieldName(mediaType);
    final List<String> searches = await getRecentSearches(mediaType);

    // Remove duplicate entry
    if (searches.contains(query)) {
      searches.remove(query);
    }

    // Add to beginning
    searches.insert(0, query);

    // Limit to 20 recent searches
    if (searches.length > 20) {
      searches.removeRange(20, searches.length);
    }

    try {
      await _getDocReference().set(<String, dynamic>{fieldName: searches}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error adding query to recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> remove(MediaType mediaType, String query) async {
    final String fieldName = _getFieldName(mediaType);
    final List<String> searches = await getRecentSearches(mediaType);

    if (searches.contains(query)) {
      searches.remove(query);
      try {
        await _getDocReference().set(<String, dynamic>{fieldName: searches}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error removing query from recent searches", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<void> clear(MediaType mediaType) async {
    try {
      final String fieldName = _getFieldName(mediaType);
      await _getDocReference().set(<String, dynamic>{fieldName: <dynamic>[]}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error clearing recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }
}