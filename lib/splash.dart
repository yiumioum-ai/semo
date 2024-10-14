import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/fragments.dart';
import 'package:semo/landing.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String version = '1.0.0';

  getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  navigate({required Widget destination}) {
    Duration duration = new Duration(
      seconds: 3,
    );

    return Timer(duration, () async {
      await Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: destination,
        ),
      );
    });
  }

  checkUserSession() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      Widget destination;
      if (user == null) {
        destination = Landing();
      } else {
        destination = Fragments();
      }
      navigate(destination: destination);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Splash',
      );
      getAppVersion();
      checkUserSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon.png',
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 10,
                      right: 16,
                      left: 16,
                    ),
                    child: Text(
                      'Version $version',
                      style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}