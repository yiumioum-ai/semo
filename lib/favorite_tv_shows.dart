import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/tv_show.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/pop_up_menu.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';

class FavoriteTvShows extends StatefulWidget {
  @override
  _FavoriteTvShowsState createState() => _FavoriteTvShowsState();
}

class _FavoriteTvShowsState extends State<FavoriteTvShows> {
  Spinner? _spinner;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<model.TvShow> _tvShows = [];
  List<int> _rawTvShows = [];

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

  Future<void> getMovies() async {
    _spinner!.show();
    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      List<int> rawTvShows = ((data['tv_shows'] ?? []) as List<dynamic>).cast<int>();
      setState(() => _rawTvShows = rawTvShows);
      for (int tvShowId in rawTvShows) getTvShowDetails(tvShowId);
    }, onError: (e) => print("Error getting user: $e"));
    _spinner!.dismiss();
  }

  Future<void> getTvShowDetails(int id) async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowDetails(id)).replace();

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      var data = json.decode(response);
      model.TvShow tvShow = model.TvShow.fromJson(data);
      setState(() => _tvShows.add(tvShow));
    } else {
      print('Failed to get movie details: $id');
    }
  }

  removeFromRecentlyWatched(model.TvShow tvShow) async {
    List<int> rawTvShows = _rawTvShows;
    rawTvShows.removeWhere((id) => id == tvShow.id);

    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.set({
      'tv_shows': rawTvShows,
    }, SetOptions(merge: true));

    setState(() {
      _tvShows.remove(tvShow);
      _rawTvShows = rawTvShows;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Favorites - TV Shows',
      );
      getMovies();
    });
  }

  Widget TvShowCard(model.TvShow tvShow) {
    List<String> firstAirDateContent = tvShow.firstAirDate.split('-');
    String firstAirYear = firstAirDateContent[0];

    return PopupMenuContainer<String>(
      items: [
        PopupMenuItem(
          value: 'remove',
          child: Text(
            'Remove',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ],
      onItemSelected: (action) async {
        if (action != null) {
          if (action == 'remove') removeFromRecentlyWatched(tvShow);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: '${Urls.imageBase_w185}${tvShow.posterPath}',
              placeholder: (context, url) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              imageBuilder: (context, image) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 8,
                              ),
                              margin: EdgeInsets.only(
                                top: 5,
                                right: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Theme.of(context).primaryColor,
                              ),
                              child: Text(
                                '${tvShow.voteAverage}',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                      ],
                    ),
                    onTap: () => navigate(destination: TvShow(tvShow, fromFavorites: true)),
                  ),
                );
              },
              errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white54),
            ),
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 10),
            child: Text(
              tvShow.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: 5,
              bottom: 10,
            ),
            child: Text(
              firstAirYear,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(18),
          child: _tvShows.isNotEmpty ? GridView.builder(
            itemCount: _tvShows.length,
            itemBuilder: (context, index) => TvShowCard(_tvShows[index]),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              childAspectRatio: 1/2,
            ),
          ) : Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.new_releases_outlined,
                  color: Colors.white54,
                  size: 80,
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    'You don\'t have any favorites',
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}