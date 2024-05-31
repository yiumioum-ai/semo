import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:page_transition/page_transition.dart';

class Player extends StatefulWidget {
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late VlcPlayerController _videoPlayerController;
  bool _isPlaying = true;

  initializePlayer() {
    setState(() {
      _videoPlayerController = VlcPlayerController.network(
        'https://ewal.v44381c4b81.site/_v2-ekbz/12a3c523fe105800ed8c394685aeeb0bc62efc5c16bbfee914037baea93ece832257df1a4b6125fcfa38c35da05dee86aad28d46d73fc4e9d4e5a57f0720afd637c711e3091fb40913c2b4bc6f4e7a1c627a99641505319fcec8b95fc2a134db2155f2/h/list;15a38634f803584ba8926411d7bee906856cab0654b5ba.m3u8',
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(

        ),
      );
    });
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Player',
      );

      initializePlayer();
    });
  }

  @override
  void dispose() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
    await _videoPlayerController.stopRendererScanning();
    await _videoPlayerController.dispose();
  }

  Widget Controls() {
    return Container(
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
              ),
            ),
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //10s back
                  //Play/Pause
                  //10s forward

                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () async {
                      bool? isPlaying = await _videoPlayerController.isPlaying();

                      if (_isPlaying) {
                        await _videoPlayerController.pause();
                      } else {
                        await _videoPlayerController.play();
                      }

                      setState(() {
                        _isPlaying = isPlaying!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          //Progress Bar
          //Current Time ----- Total Time
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            child: VlcPlayer(
              controller: _videoPlayerController,
              aspectRatio: MediaQuery.of(context).size.aspectRatio,
              placeholder: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          Controls(),
        ],
      ),
    );
  }
}