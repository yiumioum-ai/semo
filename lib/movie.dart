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
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:semo/web_player.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;

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

  getMovieDetails({bool reload = false}) async {
    if (!reload) _spinner.show();
    await Future.wait([
      isFavorite(),
      getTrailerUrl(),
      getMovieStreamUrl(),
      getMovieCast(),
      getRecommendations(),
      getSimilar(),
    ]);
    if (!reload) _spinner.dismiss();
    setState(() => _isLoading = false);
  }

  Future<void> isFavorite() async {
    final user = _firestore.collection(DB.users).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<int> favoriteMovies = (data[DB.favoriteMovies] as List<dynamic>).cast<int>();

        if (favoriteMovies.isNotEmpty) {
          _isFavorite = favoriteMovies.contains(_movie!.id);
          setState(() => _favoriteMovies = favoriteMovies);
        }
      }, onError: (e) => print("Error getting user: $e"),
    );
  }

  addToFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.add(_movie!.id);

    final user = _firestore.collection(DB.users).doc(_auth.currentUser!.uid);
    await user.set({
      DB.favoriteMovies: favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = true;
    });
  }

  removeFromFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.remove(_movie!.id);

    final user = _firestore.collection(DB.users).doc(_auth.currentUser!.uid);
    await user.set({
      DB.favoriteMovies: favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = false;
    });
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
      youtubeId = youtubeVideos[0]['key'] ?? '';
    } else {
      print('Failed to get trailer youtube url');
    }

    String youtubeUrl = 'https://www.youtube.com/watch?v=$youtubeId';
    setState(() => _movie!.trailerUrl = youtubeUrl);
  }

  Future<void> getMovieStreamUrl() async {
    String streamUrl = Urls.getMovieStreamUrl(_movie!.id);
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

  Future<void> getRecommendations() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieRecommendations(_movie!.id));
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['results'] as List;
      List<model.Movie> recommendations = data.map((json) => model.Movie.fromJson(json)).toList();
      setState(() => _movie!.recommendations = recommendations);
    } else {
      print('Failed to get movie recommendations');
    }
  }

  Future<void> getSimilar() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieSimilar(_movie!.id));
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['results'] as List;
      List<model.Movie> similar = data.map((json) => model.Movie.fromJson(json)).toList();
      setState(() => _movie!.similar = similar);
    } else {
      print('Failed to get similar movie');
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
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse(_movie!.trailerUrl!),
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

  Widget Title() {
    return Container(
      width: double.infinity,
      child: Text(
        _movie!.title,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget ReleaseYear() {
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

  Widget Play() {
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
        onPressed: () async {
          navigate(
            destination: WebPlayer(
              id: _movie!.id,
              title: _movie!.title,
              streamUrl: _movie!.streamUrl!,
            ),
          );
        },
      ),
    );
  }

  Widget Overview() {
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

  Widget Cast() {
    List<model.Person>? cast = _movie!.cast != null ? _movie!.cast!.length > 10 ? _movie!.cast!.sublist(0, 10) : _movie!.cast : [];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cast',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              GestureDetector(
                child: Text(
                  'View all',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
                ),
                onTap: () {
                  //Go to cast screen
                  //Pass full cast object as param
                },
              ),
            ],
          ),
          if (_movie!.cast != null) Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cast!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != cast.length ? 18 : 0),
                  child: PersonCard(_movie!.cast![index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget PersonCard(model.Person person) {
    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: '${Urls.imageBase_w300}${person.profilePath}',
            placeholder: (context, url) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.4,
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
                width: MediaQuery.of(context).size.width * 0.4,
                height: double.infinity,
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
                  child: Container(),
                  onTap: () {
                    //Go to person
                    //Pass person as param
                  },
                ),
              );
            },
            errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white54),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          margin: EdgeInsets.only(top: 10),
          child: Text(
            person.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget Recommendations() {
    List<model.Movie>? recommendations = _movie!.recommendations != null ? _movie!.recommendations!.length > 10 ? _movie!.recommendations!.sublist(0, 10) : _movie!.recommendations : [];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              GestureDetector(
                child: Text(
                  'View all',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
                ),
                onTap: () {
                  //Go to recommendations screen
                  //Pass full recommendations object as param
                },
              ),
            ],
          ),
          if (_movie!.recommendations != null) Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != recommendations.length ? 18 : 0),
                  child: MovieCard(_movie!.recommendations![index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget Similar() {
    List<model.Movie>? similar = _movie!.similar != null ? _movie!.similar!.length > 10 ? _movie!.similar!.sublist(0, 10) : _movie!.similar : [];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Similar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              GestureDetector(
                child: Text(
                  'View all',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
                ),
                onTap: () {
                  //Go to similar screen
                  //Pass full similar object as param
                },
              ),
            ],
          ),
          if (_movie!.similar != null) Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similar!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != similar.length ? 18 : 0),
                  child: MovieCard(_movie!.similar![index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget MovieCard(model.Movie movie) {
    List<String> releaseDateContent = movie.releaseDate.split('-');
    String releaseYear = releaseDateContent[0];

    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: '${Urls.imageBase_w185}${movie.posterPath}',
            placeholder: (context, url) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.3,
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
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
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
                  onTap: () => navigate(destination: Movie(movie: movie)),
                ),
              );
            },
            errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white54),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          margin: EdgeInsets.only(top: 10),
          child: Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.left,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          margin: EdgeInsets.only(top: 10),
          child: Text(
            releaseYear,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
            textAlign: TextAlign.left,
          ),
        ),
      ],
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
        child: RefreshIndicator(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onRefresh: () {
            setState(() {
              _isLoading = true;
              _isFavorite = false;
              _movie!.trailerUrl = null;
              _movie!.streamUrl = null;
              _movie!.cast = null;
              _movie!.recommendations = null;
              _movie!.similar = null;
            });
            return getMovieDetails(reload: true);
          },
          child: !_isLoading ? SingleChildScrollView(
            child: Column(
              children: [
                TrailerPoster(),
                Container(
                  margin: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Title(),
                      ReleaseYear(),
                      Play(),
                      Overview(),
                      Cast(),
                      if (_movie!.recommendations!.isNotEmpty) Recommendations(),
                      if (_movie!.similar!.isNotEmpty) Similar(),
                    ],
                  ),
                ),
              ],
            ),
          ) : Container(),
        ),
      ),
    );
  }
}