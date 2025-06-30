import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/db_names.dart';

class RecentlyWatchedService {
  static final RecentlyWatchedService _instance = RecentlyWatchedService._internal();
  factory RecentlyWatchedService() => _instance;
  RecentlyWatchedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<int?> getMovieProgress(int movieId) async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final movies = ((data?['movies'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        final movieData = movies['$movieId'];
        return movieData?['progress'] as int?;
      }
    } catch (e) {
      print("Error getting movie progress: $e");
    }
    return null;
  }

  Future<void> updateMovieProgress(int movieId, int progress) async {
    try {
      final data = {
        'movies': {
          '$movieId': {
            'progress': progress,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        }
      };

      await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print("Error updating movie progress: $e");
    }
  }

  Future<Map<String, Map<String, dynamic>>?> getTvShowProgress(int tvShowId, int seasonId) async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final tvShows = ((data?['tv_shows'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        if (tvShows.containsKey('$tvShowId')) {
          final showData = tvShows['$tvShowId']!;
          showData.remove('visibleInMenu');

          final seasons = showData.map<String, Map<String, dynamic>>((key, value) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          });

          if (seasons.containsKey('$seasonId')) {
            return ((seasons['$seasonId'] ?? {}) as Map<dynamic, dynamic>)
                .map<String, Map<String, dynamic>>((key, value) {
              return MapEntry(key, Map<String, dynamic>.from(value));
            });
          }
        }
      }
    } catch (e) {
      print("Error getting TV show progress: $e");
    }
    return null;
  }

  Future<void> updateEpisodeProgress(
      int tvShowId,
      int seasonId,
      int episodeId,
      int progress,
      ) async {
    try {
      // Get current data
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      Map<String, Map<String, dynamic>> tvShows = {};

      if (doc.exists) {
        final data = doc.data();
        tvShows = ((data?['tv_shows'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });
      }

      // Update episode data
      final episodeData = {
        'progress': progress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (tvShows.containsKey('$tvShowId')) {
        final showData = tvShows['$tvShowId']!;
        showData.remove('visibleInMenu');

        final seasons = showData.map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        if (seasons.containsKey('$seasonId')) {
          final episodes = ((seasons['$seasonId'] ?? {}) as Map<dynamic, dynamic>)
              .map<String, Map<String, dynamic>>((key, value) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          });

          episodes['$episodeId'] = episodeData;
          seasons['$seasonId'] = episodes;
        } else {
          seasons['$seasonId'] = {'$episodeId': episodeData};
        }

        tvShows['$tvShowId'] = {'visibleInMenu': true, ...seasons};
      } else {
        tvShows['$tvShowId'] = {
          'visibleInMenu': true,
          '$seasonId': {'$episodeId': episodeData},
        };
      }

      await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .set({'tv_shows': tvShows}, SetOptions(merge: true));
    } catch (e) {
      print("Error updating episode progress: $e");
    }
  }

  Future<void> removeEpisodeProgress(
      int tvShowId,
      int seasonId,
      int episodeId,
      ) async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final tvShows = ((data?['tv_shows'] ?? {}) as Map<dynamic, dynamic>)
          .map<String, Map<String, dynamic>>((key, value) {
        return MapEntry(key, Map<String, dynamic>.from(value));
      });

      if (tvShows.containsKey('$tvShowId')) {
        final showData = tvShows['$tvShowId']!;
        showData.remove('visibleInMenu');

        final seasons = showData.map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        if (seasons.containsKey('$seasonId')) {
          final episodes = ((seasons['$seasonId'] ?? {}) as Map<dynamic, dynamic>)
              .map<String, Map<String, dynamic>>((key, value) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          });

          episodes.remove('$episodeId');

          if (episodes.isEmpty) {
            seasons.remove('$seasonId');
          } else {
            seasons['$seasonId'] = episodes;
          }
        }

        if (seasons.isEmpty) {
          tvShows.remove('$tvShowId');
        } else {
          tvShows['$tvShowId'] = {'visibleInMenu': true, ...seasons};
        }

        await _firestore
            .collection(DB.recentlyWatched)
            .doc(_auth.currentUser!.uid)
            .set({'tv_shows': tvShows}, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error removing episode progress: $e");
    }
  }

  Future<List<int>> getRecentlyWatchedMovieIds() async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final movies = ((data?['movies'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        // Sort by timestamp (most recent first)
        final sortedEntries = movies.entries.toList()
          ..sort((a, b) {
            final timestampA = a.value['timestamp'] ?? 0;
            final timestampB = b.value['timestamp'] ?? 0;
            return timestampB.compareTo(timestampA);
          });

        return sortedEntries.map((entry) => int.parse(entry.key)).toList();
      }
    } catch (e) {
      print("Error getting recently watched movie IDs: $e");
    }
    return [];
  }

  Future<void> removeMovieFromRecentlyWatched(int movieId) async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final movies = ((data?['movies'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        movies.remove('$movieId');

        await _firestore
            .collection(DB.recentlyWatched)
            .doc(_auth.currentUser!.uid)
            .set({'movies': movies}, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error removing movie from recently watched: $e");
    }
  }

  Future<List<int>> getRecentlyWatchedTvShowIds() async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final tvShows = ((data?['tv_shows'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        // Filter only visible shows and sort by timestamp
        final visibleShows = tvShows.entries
            .where((entry) => entry.value['visibleInMenu'] != false)
            .toList();

        visibleShows.sort((a, b) {
          // Get the latest timestamp from any episode in the show
          final aSeasons = Map<String, dynamic>.from(a.value)..remove('visibleInMenu');
          final bSeasons = Map<String, dynamic>.from(b.value)..remove('visibleInMenu');

          int aLatest = 0;
          int bLatest = 0;

          for (final season in aSeasons.values) {
            if (season is Map) {
              for (final episode in season.values) {
                if (episode is Map && episode['timestamp'] != null) {
                  aLatest = math.max(aLatest, episode['timestamp'] as int);
                }
              }
            }
          }

          for (final season in bSeasons.values) {
            if (season is Map) {
              for (final episode in season.values) {
                if (episode is Map && episode['timestamp'] != null) {
                  bLatest = math.max(bLatest, episode['timestamp'] as int);
                }
              }
            }
          }

          return bLatest.compareTo(aLatest);
        });

        return visibleShows.map((entry) => int.parse(entry.key)).toList();
      }
    } catch (e) {
      print("Error getting recently watched TV show IDs: $e");
    }
    return [];
  }

  Future<void> removeTvShowFromRecentlyWatched(int tvShowId) async {
    try {
      final doc = await _firestore
          .collection(DB.recentlyWatched)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final tvShows = ((data?['tv_shows'] ?? {}) as Map<dynamic, dynamic>)
            .map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        if (tvShows.containsKey('$tvShowId')) {
          tvShows['$tvShowId']!['visibleInMenu'] = false;

          await _firestore
              .collection(DB.recentlyWatched)
              .doc(_auth.currentUser!.uid)
              .set({'tv_shows': tvShows}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print("Error removing TV show from recently watched: $e");
    }
  }
}