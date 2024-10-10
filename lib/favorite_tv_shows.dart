import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class FavoriteTvShows extends StatefulWidget {
  @override
  _FavoriteTvShowsState createState() => _FavoriteTvShowsState();
}

class _FavoriteTvShowsState extends State<FavoriteTvShows> {

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Favorite TV Shows',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Favorites - TV Shows',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}