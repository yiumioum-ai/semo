//Auto play trailer on top
//Below, there is play button and download button
//Below, other info like synopsis, cast, recommended, similar etc
//Like netflix
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
import 'package:semo/models/media.dart' as model;
import 'package:semo/player.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';

//ignore: must_be_immutable
class Movie extends StatefulWidget {
  model.Movie movie;

  Movie({
    required this.movie,
  });

  @override
  _MovieState createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  model.Movie? _movie;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  List<int> _favoriteMovies = [];
  late Spinner _spinner;

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

  isFavorite() async {
    final user = _firestore.collection('users').doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<int> favoriteMovies = (data['favorite_movies'] as List<dynamic>).cast<int>();

        if (favoriteMovies.isNotEmpty) {
          _isFavorite = favoriteMovies.contains(_movie!.id);
          setState(() => _favoriteMovies = favoriteMovies);
        }
      },
      onError: (e) => print("Error getting user: $e"),
    );
  }

  addToFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.add(_movie!.id);

    final user = _firestore.collection('users').doc(_auth.currentUser!.uid);
    await user.set({
      'favorite_movies': favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = true;
    });
  }

  removeFromFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.remove(_movie!.id);

    final user = _firestore.collection('users').doc(_auth.currentUser!.uid);
    await user.set({
      'favorite_movies': favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = false;
    });
  }

  getYoutubeStreamUrl(String youtubeId) async {
    Map<String, String> headers = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    Map<String, dynamic> body = {
      'url': 'https://www.youtube.com/watch?v=$youtubeId',
      'videoQuality': '720',
    };

    Uri uri = Uri.parse(Urls.youtubeStream);

    Response request = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    late String streamUrl;
    if (response.isNotEmpty) {
      Map<String, dynamic> data = json.decode(response) as Map<String, dynamic>;
      streamUrl = data['url'];
    } else {
      print('Failed to get trailer stream url');
    }

    return streamUrl;
  }

  getTrailerUrl() async {
    _spinner.show();
    String youtubeId = '';

    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieVideosUrl(_movie!.id));

    Response request = await http.get(
      uri,
      headers: headers,
    );

    _spinner.dismiss();

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List videos = json.decode(response)['results'] as List;
      List youtubeVideos = videos.where((video) {
        return video['site'] == 'YouTube' && video['type'] == 'Trailer' && video['official'] == true;
      }).toList();
      youtubeVideos.sort((a, b) => b['size'].compareTo(a['size']));
      youtubeId = youtubeVideos[0]['key'];
    } else {
      print('Failed to get trailer youtube url');
    }

    String streamUrl = await getYoutubeStreamUrl(youtubeId);

    return streamUrl;
  }

  @override
  void initState() {
    _movie = widget.movie;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Movie - ${_movie!.title}',
      );
      await isFavorite();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : Colors.white,
            onPressed: () async {
              if (_isFavorite) {
                await removeFromFavorites();
              } else {
                await addToFavorites();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CachedNetworkImage(
                imageUrl: Urls.getBestImageUrl(context) + _movie!.backdropPath,
                placeholder: (context, url) {
                  return Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 0.4,
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                imageBuilder: (context, image) {
                  return Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: Icon(Icons.play_arrow),
                              color: Colors.white,
                              onPressed: () async {
                                String trailerUrl = await getTrailerUrl();
                                await navigate(
                                  destination: Player(
                                    streamUrl: trailerUrl,
                                    title: '${_movie!.title} - Trailer',
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Text(
                              'Play Trailer',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}