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
import 'package:semo/models/movie.dart' as model;
import 'package:semo/movie.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/pop_up_menu.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';

class FavoriteMovies extends StatefulWidget {
  @override
  _FavoriteMoviesState createState() => _FavoriteMoviesState();
}

class _FavoriteMoviesState extends State<FavoriteMovies> {
  Spinner? _spinner;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<model.Movie> _movies = [];
  List<int> _rawMovies = [];

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
    final user = _firestore.collection(DB.users).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<int> rawMovies = (data[DB.favoriteMovies] as List<dynamic>).cast<int>();
      setState(() => _rawMovies = rawMovies);
      for (int movieId in rawMovies) getMovieDetails(movieId);
    }, onError: (e) => print("Error getting user: $e"));
    _spinner!.dismiss();
  }

  Future<void> getMovieDetails(int id) async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieDetails(id)).replace();

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      var data = json.decode(response);
      model.Movie movie = model.Movie.fromJson(data);
      setState(() => _movies.add(movie));
    } else {
      print('Failed to get movie details: $id');
    }
  }

  removeFromRecentlyWatched(model.Movie movie) async {
    List<int> rawMovies = _rawMovies;
    rawMovies.removeWhere((id) => id == movie.id);

    final user = _firestore.collection(DB.users).doc(_auth.currentUser!.uid);
    await user.set({
      DB.favoriteMovies: rawMovies,
    }, SetOptions(merge: true));

    setState(() {
      _movies.remove(movie);
      _rawMovies = rawMovies;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Favorites - Movies',
      );
      getMovies();
    });
  }

  Widget MovieCard(model.Movie movie) {
    List<String> releaseDateContent = movie.releaseDate.split('-');
    String releaseYear = releaseDateContent[0];

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
          if (action == 'remove') removeFromRecentlyWatched(movie);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: '${Urls.imageBase_w185}${movie.posterPath}',
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
                                '${movie.voteAverage}',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                      ],
                    ),
                    onTap: () => navigate(destination: Movie(movie: movie, fromFavorites: true)),
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
              movie.title,
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
              releaseYear,
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
          child: _movies.isNotEmpty ? GridView.builder(
            itemCount: _movies.length,
            itemBuilder: (context, index) => MovieCard(_movies[index]),
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