//Auto play trailer on top
//Below, there is play button and download button
//Below, other info like synopsis, cast, recommended, similar etc
//When a person from cast is selected, it should show the person's movies/shows
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
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/person.dart' as model;
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
    PageTransition pageTransition = PageTransition(
      type: PageTransitionType.rightToLeft,
      child: destination,
    );

    if (replace) {
      await Navigator.pushReplacement(
        context,
        pageTransition,
      );
    } else {
      await Navigator.push(
        context,
        pageTransition,
      );
    }
  }

  getMovieDetails() async {
    _spinner.show();
    await Future.wait([
      isFavorite(),
      getTrailerUrl(),
      getMovieStreamUrl(),
      getMovieCast(),
    ]);
    _spinner.dismiss();
  }

  Future<void> isFavorite() async {
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

  Future<void> getTrailerUrl() async {
    String youtubeId = '';

    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieVideosUrl(_movie!.id));

    Response request = await http.get(
      uri,
      headers: headers,
    );

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
    setState(() => _movie!.trailerUrl = streamUrl);
  }

  Future<void> getMovieStreamUrl() async {
    Uri uri = Uri.parse(Urls.getMovieStreamUrl(_movie!.id));

    Response request = await http.get(uri);

    String response = request.body;
    if (!kReleaseMode) print(response);

    late String streamUrl;
    if (response.isNotEmpty) {
      Map<String, dynamic> data = json.decode(response)[0] as Map<String, dynamic>;
      streamUrl = data['stream'];
    } else {
      print('Failed to get movie stream url');
    }

    setState(() => _movie!.streamUrl = streamUrl);
  }

  Future<void> getMovieCast() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieCast(_movie!.id)).replace();

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['cast'] as List;
      List<model.Person> allCast = data.map((json) => model.Person.fromJson(json)).toList();
      List<model.Person> cast = allCast.where((model.Person person) => person.department == 'Acting').toList();

      setState(() => _movie!.cast = cast);
    } else {
      print('Failed to get movie cast');
    }
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
      await getMovieDetails();
    });
  }

  Widget TrailerPoster() {
    return CachedNetworkImage(
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
                    onPressed: () {
                      navigate(
                        destination: Player(
                          streamUrl: _movie!.trailerUrl!,
                          title: '${_movie!.title} - Trailer',
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    'Play trailer',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  Widget MovieTitle() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20),
      child: Text(
        _movie!.title,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget MovieReleaseYear() {
    String releaseYear = _movie!.releaseDate.split('-')[0];
    return Container(
      width: double.infinity,
      child: Text(
        releaseYear,
        style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget PlayMovie() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.only(top: 20),
      child: ElevatedButton(
        child: Container(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(right: 5),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              Text(
                'Play',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          navigate(
            destination: Player(
              streamUrl: _movie!.streamUrl!,
              title: _movie!.title,
            ),
          );
        },
      ),
    );
  }

  Widget MovieOverview() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20),
      child: Text(
        _movie!.overview,
        style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
        textAlign: TextAlign.justify,
      ),
    );
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
              TrailerPoster(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    MovieTitle(),
                    MovieReleaseYear(),
                    PlayMovie(),
                    MovieOverview(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}