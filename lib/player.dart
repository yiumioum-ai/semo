import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/duration_state.dart';

//ignore: must_be_immutable
class Player extends StatefulWidget {
  String title, streamUrl;

  Player({
    required this.title,
    required this.streamUrl,
  });

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with TickerProviderStateMixin {
  String? _title, _streamUrl;
  VlcPlayerController? _videoPlayerController;
  DurationState _durationState = DurationState(
    progress: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );
  bool _isPlaying = true, _showControls = true;
  AnimationController? _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation = AlwaysStoppedAnimation<double>(1.0);
  double _lastZoomGestureScale = 1.0;

  initializePlayer() {
    setState(() {
      _videoPlayerController = VlcPlayerController.network(
        _streamUrl!,
        hwAcc: HwAcc.auto,
        autoPlay: true,
        autoInitialize: true,
        options: VlcPlayerOptions(
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
        ),
      );
    });

    _videoPlayerController!.addOnInitListener(() {
      streamUpdates();
      Future.delayed(Duration(seconds: 5), () {
        setState(() => _showControls = false);
      });
    });
  }

  streamUpdates() async {
    Duration progress = await _videoPlayerController!.getPosition();
    Duration total = await _videoPlayerController!.getDuration();
    Duration buffered = Duration(
      seconds: ((_videoPlayerController!.value.bufferPercent * total.inSeconds) / 100).round(),
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
    } else {
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

    bool? isPlaying = await _videoPlayerController!.isPlaying();
    setState(() {
      _isPlaying = isPlaying!;
      _showControls = !isPlaying;
    });
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
    _title = widget.title;
    _streamUrl = widget.streamUrl;
    super.initState();
    forceLandscape();

    _scaleVideoAnimationController = AnimationController(
      duration: Duration(milliseconds: 125),
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

    if (_isPlaying) await _videoPlayerController!.pause();
    _videoPlayerController!.removeOnInitListener(() {});
    await _videoPlayerController!.dispose();
  }

  Widget VideoPlayer() {
    return Center(
      child: ScaleTransition(
        scale: _scaleVideoAnimation,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VlcPlayer(
            controller: _videoPlayerController!,
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
                  leading: BackButton(color: Colors.white),
                  title: Text(
                    _title!,
                    style: Theme.of(context).textTheme.titleSmall,
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
                      onPressed: () => seekBack(),
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
                        onPressed: () => playPause(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => seekForward(),
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
                    onSeek: (target) => seek(target),
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
    if (_videoPlayerController != null) initializeScaling();

    return Scaffold(
      body: _videoPlayerController != null ? GestureDetector(
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
          if (_lastZoomGestureScale > 1.0) {
            setState(() => _scaleVideoAnimationController!.forward());
          } else if (_lastZoomGestureScale < 1.0) {
            setState(() => _scaleVideoAnimationController!.reverse());
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
      ) : Container(),
    );
  }
}