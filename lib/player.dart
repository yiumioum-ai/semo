import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/duration_state.dart';

class Player extends StatefulWidget {
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with TickerProviderStateMixin {
  late VlcPlayerController _videoPlayerController;
  DurationState _durationState = DurationState(
    progress: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );
  bool _isPlaying = true;
  bool _showControls = true;
  late AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation = AlwaysStoppedAnimation<double>(1.0);
  double _lastZoomGestureScale = 1.0;

  initializePlayer() {
    setState(() {
      _videoPlayerController = VlcPlayerController.network(
        'https://ewal.v44381c4b81.site/_v2-ekbz/9a701df34ea7e4ae16c25b01dd7fefae771974c45e1c81b9948778fe4fcd06741ae3e719f0ef63837c6cf62e8daaecb28d7ff9aa0d734593957b6d8b83565f6c2fa332d13fc9abac36c2e822d50a918d06c160eaf2e98f5ec3340eb8e9c7f9e5727599/h/list;9d705ee448b4e4e553dc06568f6feda3345b239e1c12c6.m3u8',
        hwAcc: HwAcc.auto,
        autoPlay: true,
        autoInitialize: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(10000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
        ),
      );
    });

    _videoPlayerController.addOnInitListener(() {
      streamUpdates();
      Future.delayed(Duration(seconds: 5), () {
        setState(() {
          _showControls = false;
        });
      });
    });
  }

  streamUpdates() async {
    Duration progress = await _videoPlayerController.getPosition();
    Duration total = await _videoPlayerController.getDuration();
    Duration buffered = Duration(
      seconds: ((_videoPlayerController.value.bufferPercent * total.inSeconds) / 100).round(),
    );

    setState(() {
      _durationState = DurationState(
        progress: progress,
        buffered: buffered,
        total: total,
      );
    });

    if (total.inSeconds == 0 || progress != total) {
      streamUpdates();
    }
  }

  playPause() async {
    if (_isPlaying) {
      await _videoPlayerController.pause();
    } else {
      await _videoPlayerController.play();
    }

    bool? isPlaying = await _videoPlayerController.isPlaying();
    setState(() {
      _isPlaying = isPlaying!;
      _showControls = !isPlaying;
    });
  }

  seekForward() async {
    Duration currentPosition = await _videoPlayerController.getPosition();
    Duration targetPosition = Duration(
      seconds: currentPosition.inSeconds + 10,
    );
    await _videoPlayerController.seekTo(targetPosition);
  }

  seekBack() async {
    Duration currentPosition = await _videoPlayerController.getPosition();
    Duration targetPosition = Duration(
      seconds: currentPosition.inSeconds - 10,
    );
    await _videoPlayerController.seekTo(targetPosition);
  }

  seek(Duration target) async {
    await _videoPlayerController.seekTo(target);
  }

  initializeScaling() {
    Size screenSize = MediaQuery.of(context).size;
    Size videoSize = _videoPlayerController.value.size;
    double targetScale = screenSize.width / (videoSize.width * screenSize.height / videoSize.height);

    _scaleVideoAnimation = Tween<double>(
      begin: 1.0,
      end: targetScale,
    ).animate(
      CurvedAnimation(
        parent: _scaleVideoAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  forceLandscape() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  forcePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
    super.initState();
    forceLandscape();

    _scaleVideoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Player',
      );

      initializePlayer();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    forcePortrait();
    _videoPlayerController.removeOnInitListener(() {});
    await _videoPlayerController.dispose();
  }

  Widget VideoPlayer() {
    return Center(
      child: ScaleTransition(
        scale: _scaleVideoAnimation,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VlcPlayer(
            controller: _videoPlayerController,
            aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
            placeholder: Center(
              child: CircularProgressIndicator(),
            ),
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
                    color: Colors.white,
                  ),
                  title: Text(
                    'Dune: Part Two',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.closed_caption_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        //Show captions selection dialog
                        //Pause media when open
                        //Play media when close
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
                      onPressed: () {
                        seekBack();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 42,
                        ),
                        onPressed: () {
                          playPause();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        seekForward();
                      },
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
                    buffered: _durationState.buffered,
                    total: _durationState.total,
                    progressBarColor: Theme.of(context).primaryColor,
                    baseBarColor: Theme.of(context).primaryColor.withOpacity(.2),
                    bufferedBarColor: Theme.of(context).primaryColor.withOpacity(.5),
                    thumbColor: Theme.of(context).primaryColor,
                    timeLabelTextStyle: Theme.of(context).textTheme.displaySmall,
                    timeLabelPadding: 10,
                    onSeek: (target) {
                      seek(target);
                    },
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
    initializeScaling();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          if (_showControls) {
            setState(() {
              _showControls = false;
            });
          } else {
            setState(() {
              _showControls = true;
            });
            Future.delayed(const Duration(seconds: 5), () {
              if (_isPlaying) {
                setState(() {
                  _showControls = false;
                });
              }
            });
          }
        },
        onScaleUpdate: (details) {
          _lastZoomGestureScale = details.scale;
        },
        onScaleEnd: (details) {
          if (_lastZoomGestureScale > 1.0) {
            setState(() {
              // Zoom in
              _scaleVideoAnimationController.forward();
            });
          } else if (_lastZoomGestureScale < 1.0) {
            setState(() {
              // Zoom out
              _scaleVideoAnimationController.reverse();
            });
          }
          _lastZoomGestureScale = 1.0;
        },
        child: Stack(
          children: [
            Container(
              color: Colors.black,
            ),
            VideoPlayer(),
            Controls(),
          ],
        ),
      ),
    );
  }
}