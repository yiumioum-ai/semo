import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/duration_state.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/enums.dart';

//ignore: must_be_immutable
class Player extends StatefulWidget {
  int id;
  int? episodeId;
  String title, streamUrl;
  PageType pageType;

  Player({
    required this.id,
    this.episodeId,
    required this.title,
    required this.streamUrl,
    required this.pageType,
  });

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with TickerProviderStateMixin {
  int? _id, _episodeId;
  String? _title, _streamUrl;
  PageType? _pageType;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  VlcPlayerController? _videoPlayerController;
  DurationState _durationState = DurationState(
    progress: Duration.zero,
    total: Duration.zero,
    isBuffering: true,
  );
  bool _isPlaying = true;
  bool _showControls = true;
  AnimationController? _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation = AlwaysStoppedAnimation<double>(1.0);
  double _lastZoomGestureScale = 1.0;
  bool _isZoomedIn = false;

  updateRecentlyWatched() async {
    final user = _firestore.collection(DB.recentlyWatched).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      var recentlyWatched;

      if (_pageType == PageType.movies) {
        recentlyWatched = ((data['movies'] ?? []) as List<dynamic>).cast<Map<String, dynamic>>();
        bool isInRecentlyWatched = recentlyWatched.any((movie) => movie['id'] == _id);

        if (recentlyWatched.isNotEmpty && isInRecentlyWatched) {
          for (Map<String, dynamic> movie in recentlyWatched) {
            if (movie['id'] == _id) {
              if (_videoPlayerController != null) movie['progress'] = _durationState.progress.inSeconds;
              movie['timestamp'] = DateTime.now().millisecondsSinceEpoch;

              if (movie['progress'] != null && movie['progress'] != 0) {
                if (mounted) setState(() => _durationState.progress = Duration(seconds: movie['progress']));
              }
              break;
            }
          }
        } else {
          recentlyWatched.add({
            'id': _id,
            if (_videoPlayerController != null) 'progress': _durationState.progress.inSeconds,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } else {
        recentlyWatched = ((data['tv_shows'] ?? {}) as Map<int, dynamic>);

        if (recentlyWatched.containsKey(_id)) {
          List<dynamic> episodes = recentlyWatched[_id] as List<dynamic>;
          bool isEpisodeInRecentlyWatched = episodes.any((episode) => episode['episode_id'] == _episodeId);

          if (episodes.isNotEmpty && isEpisodeInRecentlyWatched) {
            for (Map<String, dynamic> episode in episodes) {
              if (episode['episode_id'] == _episodeId) {
                if (_videoPlayerController != null) episode['progress'] = _durationState.progress.inSeconds;
                episode['timestamp'] = DateTime.now().millisecondsSinceEpoch;

                if (episode['progress'] != null && episode['progress'] != 0) {
                  if (mounted) setState(() => _durationState.progress = Duration(seconds: episode['progress']));
                }
                break;
              }
            }
          } else {
            episodes.add({
              'episode_id': _episodeId,
              if (_videoPlayerController != null) 'progress': _durationState.progress.inSeconds,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        } else {
          recentlyWatched[_id] = [{
            'episode_id': _episodeId,
            if (_videoPlayerController != null) 'progress': _durationState.progress.inSeconds,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }];
        }
      }

      user.set({
        _pageType!.name: recentlyWatched,
      }, SetOptions(merge: true));
    }, onError: (e) => print("Error getting user: $e"));
  }

  initializePlayer() async {
    setState(() {
      _videoPlayerController = VlcPlayerController.network(
        _streamUrl!,
        hwAcc: HwAcc.auto,
        autoInitialize: true,
        autoPlay: true,
        options: VlcPlayerOptions(
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
        ),
      );
    });

    _videoPlayerController!.addOnInitListener(() async {
      int currentPosition = 0;

      while (currentPosition == 0) {
        currentPosition = (await _videoPlayerController!.getPosition()).inSeconds;
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (_durationState.progress.inSeconds != 0 && _videoPlayerController!.value.isPlaying && !_videoPlayerController!.value.isBuffering) {
        await seek(_durationState.progress);
      }

      streamUpdates();

      Future.delayed(Duration(seconds: 5), () async {
        setState(() => _showControls = false);
      });

      Timer.periodic(Duration(seconds: 30), (timer) {
        if (mounted) updateRecentlyWatched();
      });
    });
  }

  streamUpdates() async {
    Duration progress = await _videoPlayerController!.getPosition();
    Duration total = await _videoPlayerController!.getDuration();
    bool isBuffering = false;
    bool isPlaying = await _videoPlayerController!.isPlaying() ?? false;

    if (_videoPlayerController!.value.isBuffering) {
      isBuffering = true;
    } else {
      if (isPlaying && (progress == _durationState.progress)) {
        isBuffering = true;
      }
    }

    setState(() {
      _durationState = DurationState(
        progress: progress,
        total: total,
        isBuffering: isBuffering,
      );
      _isPlaying = isPlaying;
      _showControls = !isPlaying;
    });

    if (total.inSeconds == 0 || progress != total) {
      if (mounted) streamUpdates();
    } else {
      updateRecentlyWatched();
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
      Navigator.of(context).pop();
    }
  }

  playPause() async {
    if (_isPlaying) {
      await _videoPlayerController!.pause();
    } else {
      await _videoPlayerController!.play();
    }
  }

  seekForward() async {
    Duration currentPosition = await _videoPlayerController!.getPosition();
    Duration targetPosition = Duration(seconds: currentPosition.inSeconds + 10);
    await _videoPlayerController!.seekTo(targetPosition);
  }

  seekBack() async {
    Duration currentPosition = await _videoPlayerController!.getPosition();
    Duration targetPosition = Duration(
      seconds: currentPosition.inSeconds - (currentPosition.inSeconds < 10 ? currentPosition.inSeconds : 10),
    );
    await _videoPlayerController!.seekTo(targetPosition);
  }

  seek(Duration target) async => await _videoPlayerController!.seekTo(target);

  initializeScaling() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      Size screenSize = MediaQuery.of(context).size;
      Size videoSize = _videoPlayerController!.value.size;
      double targetScale = screenSize.width / (videoSize.width * screenSize.height / videoSize.height);

      _scaleVideoAnimation = Tween<double>(
        begin: 1.0,
        end: targetScale,
      ).animate(
        CurvedAnimation(
          parent: _scaleVideoAnimationController!,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  forceLandscape() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  forcePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  navigate({required Widget destination, bool replace = false}) async {
    if (replace) {
      await Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: destination,
        ),
      );
    } else {
      await Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: destination,
        ),
      );
    }
  }

  @override
  void initState() {
    _id = widget.id;
    _episodeId = widget.episodeId;
    _title = widget.title;
    _streamUrl = widget.streamUrl;
    _pageType = widget.pageType;
    super.initState();
    forceLandscape();

    _scaleVideoAnimationController = AnimationController(
      duration: Duration(milliseconds: 125),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await updateRecentlyWatched();
      await initializePlayer();
      initializeScaling();
    });
  }

  @override
  void dispose() async {
    forcePortrait();

    if (_isPlaying) await _videoPlayerController!.pause();
    _videoPlayerController!.dispose();
    _videoPlayerController = null;
    super.dispose();
  }

  Widget VideoPlayer() {
    double aspectRatio = _isZoomedIn
        ? MediaQuery.of(context).size.width / MediaQuery.of(context).size.height
        : _videoPlayerController!.value.aspectRatio;
    return Center(
      child: ScaleTransition(
        scale: _scaleVideoAnimation,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VlcPlayer(
            controller: _videoPlayerController!,
            aspectRatio: aspectRatio,
            placeholder: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget Controls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1 : 0,
      duration: Duration(
        milliseconds: 300,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.5),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  leading: BackButton(
                    onPressed: () async {
                      await updateRecentlyWatched();
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(_title!),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.closed_caption_off),
                      onPressed: () {
                        //Show captions selection dialog
                        //Pause media when open
                        //Play media when close
                      },
                    ),
                    IconButton(
                      icon: Icon(_isZoomedIn ? Icons.zoom_out_map : Icons.zoom_in_map),
                      onPressed: () {
                        setState(() {
                          if (_isZoomedIn) {
                            _scaleVideoAnimationController!.reverse();
                          } else {
                            _scaleVideoAnimationController!.forward();
                          }
                          _isZoomedIn = !_isZoomedIn;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => !_durationState.isBuffering ? seekBack() : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      child: !_durationState.isBuffering ? IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 42,
                        ),
                        onPressed: () => playPause(),
                      ) : CircularProgressIndicator(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => !_durationState.isBuffering ? seekForward() : null,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    bottom: 18,
                  ),
                  child: ProgressBar(
                    progress: _durationState.progress,
                    total: _durationState.total,
                    progressBarColor: Theme.of(context).primaryColor,
                    baseBarColor: Theme.of(context).primaryColor.withOpacity(.2),
                    bufferedBarColor: Theme.of(context).primaryColor.withOpacity(.5),
                    thumbColor: Theme.of(context).primaryColor,
                    timeLabelTextStyle: Theme.of(context).textTheme.displaySmall,
                    timeLabelPadding: 10,
                    onSeek: (target) => !_durationState.isBuffering ? seek(target) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videoPlayerController != null ? SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_showControls) {
              setState(() => _showControls = false);
            } else {
              setState(() => _showControls = true);
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted && _isPlaying) {
                  setState(() => _showControls = false);
                }
              });
            }
          },
          onScaleUpdate: (details) {
            _lastZoomGestureScale = details.scale;
          },
          onScaleEnd: (details) {
            if (_lastZoomGestureScale < 1.0) {
              setState(() {
                _scaleVideoAnimationController!.forward();
                _isZoomedIn = true;
              });
            } else if (_lastZoomGestureScale > 1.0) {
              setState(() {
                _scaleVideoAnimationController!.reverse();
                _isZoomedIn = false;
              });
            }
            _lastZoomGestureScale = 1.0;
          },
          child: Stack(
            children: [
              Container(color: Colors.black),
              VideoPlayer(),
              Controls(),
            ],
          ),
        ),
      ) : Container(),
    );
  }
}