//Auto play trailer on top
//Below, there is play button and download button
//Below, other info like synopsis, cast, etc
//Like netflix
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/movie.dart' as model;

class Movie extends StatefulWidget {
  model.Movie movie;
  Movie({
    required this.movie,
  });
  @override
  _MovieState createState() => _MovieState();
}

class _MovieState extends State<Movie> {

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
        screenName: 'Movie',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Movie',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}