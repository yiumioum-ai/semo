import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:semo/components/semo_player.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/enums/media_type.dart";
import "package:wakelock_plus/wakelock_plus.dart";

class PlayerScreen extends BaseScreen {
  const PlayerScreen({
    super.key,
    required this.tmdbId,
    this.seasonId,
    this.episodeId,
    required this.title,
    required this.stream,
    required this.mediaType,
  }) : assert(mediaType != MediaType.tvShows || (seasonId != null && episodeId != null),
  "seasonId and episodeId must be provided when mediaType is tvShows"
  );

  final int tmdbId;
  final int? seasonId;
  final int? episodeId;
  final String title;
  final MediaStream stream;
  final MediaType mediaType;

  @override
  BaseScreenState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends BaseScreenState<PlayerScreen> {
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  int _watchedProgressSeconds = 0;

  Future<void> _initializeWatchedProgress() async {
    try {
      if (widget.mediaType == MediaType.movies) {
        final int? progress = await _recentlyWatchedService.getMovieProgress(widget.tmdbId);
        if (progress != null && progress > 0) {
          setState(() => _watchedProgressSeconds = progress);
        }
      } else {
        final int? progress = await _recentlyWatchedService.getEpisodeProgress(
          widget.tmdbId,
          widget.seasonId!,
          widget.episodeId!,
        );
        if (progress != null && progress > 0) {
          setState(() => _watchedProgressSeconds = progress);
        }
      }
    } catch (_) {}
  }

  Future<void> _updateRecentlyWatched(int progressSeconds) async {
    try {
      if (widget.mediaType == MediaType.movies) {
        await _recentlyWatchedService.updateMovieProgress(widget.tmdbId, progressSeconds);
      } else {
        await _recentlyWatchedService.updateEpisodeProgress(
          widget.tmdbId,
          widget.seasonId!,
          widget.episodeId!,
          progressSeconds,
        );
      }
    } catch (_) {}
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _onProgress(Duration progress, Duration total) {
    if (total.inSeconds > 0) {
      final int progressSeconds = progress.inSeconds;
      if (progressSeconds > 0) {
        _updateRecentlyWatched(progressSeconds);
      }
    }
  }

  //ignore: avoid_annotating_with_dynamic
  void _onError(dynamic error) {
    logger.e("Playback error", error: error);
    if (mounted) {
      Navigator.pop(context, <String, dynamic>{"error": error});
    }
  }

  Future<void> _saveThenGoBack() async {
    if (mounted) {
      Navigator.pop(context, <String, dynamic>{
        if (widget.episodeId != null) "episodeId": widget.episodeId,
        "progress": _watchedProgressSeconds,
      });
    }
  }

  @override
  String get screenName => "Semo Player - ${widget.tmdbId}";

  @override
  Future<void> initializeScreen() async {
    await WakelockPlus.enable();
    await _forceLandscape();
    await _initializeWatchedProgress();
  }

  @override
  void handleDispose() {
    _forcePortrait();
    WakelockPlus.disable();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: SemoPlayer(
      stream: widget.stream,
      title: widget.title,
      initialProgress: _watchedProgressSeconds,
      onProgress: _onProgress,
      onPlaybackComplete: _saveThenGoBack,
      onBack: _saveThenGoBack,
      onError: _onError,
    ),
  );
}