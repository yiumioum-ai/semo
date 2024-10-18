import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/tv_show.dart' as model;

//ignore: must_be_immutable
class TvShow extends StatefulWidget {
  model.TvShow tvShow;
  bool fromFavorites;

  TvShow(this.tvShow, {
    this.fromFavorites = false,
  });

  @override
  _TvShowState createState() => _TvShowState();
}

class _TvShowState extends State<TvShow> {
  model.TvShow? _tvShow;
  bool? _fromFavorites;

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
    _tvShow = widget.tvShow;
    _fromFavorites = widget.fromFavorites;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'TV Show',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'TV Show',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}