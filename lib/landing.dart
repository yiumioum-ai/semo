import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/fragments.dart';
import 'package:video_player/video_player.dart';

class Landing extends StatefulWidget {
  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  VideoPlayerController? _controller;
  bool _visible = false;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  initializeVideo() {
    _controller = VideoPlayerController.asset('assets/cover.mp4');
    _controller!.initialize().then((_) {
      _controller!.setLooping(true);
      Timer(Duration(milliseconds: 100), () {
        setState(() {
          _controller!.play();
          _visible = true;
        });
      });
    });
  }

  googleAuthentication() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn(
      clientId: '373107998814-sd19gobakp05i2e9mm9hpk0lg4uecr84.apps.googleusercontent.com',
    ).signIn();
    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    var credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signInWithCredential(credential);

      String uid = auth.currentUser!.uid;

      final user = _firestore.collection('users').doc(uid);
      await user.get().then((DocumentSnapshot doc) async {
          bool isRegistered = doc.exists;

          if (!isRegistered) {
            await user.set({
              'recently_watched_movies': [],
              'recently_watched_tv_shows': [],
              'favorite_movies': [],
              'favorite_tv_shows': [],
            });
          }
        },
        onError: (e) => print("Error getting user: $e"),
      );

      navigate(destination: Fragments());
    } catch (e) {
      print(e);
    }
  }

  navigate({required Widget destination}) async {
    await Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: destination,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Landing',
      );

      initializeVideo();
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
  }

  Widget VideoBackground() {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(
        milliseconds: 1000,
      ),
      child: VideoPlayer(_controller!),
    );
  }

  Widget BackgroundTint() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.5),
    );
  }

  Widget ContinueWithGoogle() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        child: Container(
          width: double.infinity,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: 16,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Spacer(),
                      Text(
                        'Continue with Google',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      Spacer(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          side: BorderSide(
            width: 3,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          googleAuthentication();
        },
      ),
    );
  }

  Widget Content() {
    return Column(
      children: [
        Spacer(),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 36),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    'Discover a vast library of entertainment, from blockbuster hits to indie gems, all tailored to your tastes. Enjoy unlimited streaming on any device, create your personalized watchlist, and get ready for an unparalleled viewing experience.',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: ContinueWithGoogle(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller != null ? Stack(
        children: [
          VideoBackground(),
          BackgroundTint(),
          Content(),
        ],
      ) : Container(),
    );
  }
}