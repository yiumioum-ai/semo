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
import 'package:semo/fragments.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/person.dart' as model;
import 'package:semo/player.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/extractor.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:url_launcher/url_launcher.dart';

//ignore: must_be_immutable
class Movie extends StatefulWidget {
  model.Movie movie;
  bool fromFavorites;

  Movie(this.movie, {
    this.fromFavorites = false,
  });

  @override
  _MovieState createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  model.Movie? _movie;
  bool? _isRecentlyWatched, _fromFavorites;
  int? _watchedProgress;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  List<int> _favoriteMovies = [];
  late Spinner _spinner;
  bool _isLoading = true;

  navigate({required Widget destination, bool replace = false, bool goingBack = false}) async {
    PageTransition pageTransition = PageTransition(
      type: !goingBack ? PageTransitionType.rightToLeft : PageTransitionType.leftToRight,
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
      isRecentlyWatched(),
      getTrailerUrl(),
      getMovieDuration(),
      getMovieStreamUrl(),
      getMovieCast(),
      getRecommendations(),
      getSimilar(),
    ]);
    if (!reload) _spinner.dismiss();
    setState(() => _isLoading = false);
  }

  Future<void> isFavorite() async {
    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      List<int> favoriteMovies = ((data['movies'] ?? []) as List<dynamic>).cast<int>();

      if (favoriteMovies.isNotEmpty) {
        setState(() {
          _isFavorite = favoriteMovies.contains(_movie!.id);
          _favoriteMovies = favoriteMovies;
        });
      }
    }, onError: (e) => print("Error getting user: $e"));
  }

  addToFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.add(_movie!.id);

    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.set({
      'movies': favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = true;
    });
  }

  removeFromFavorites() async {
    List<int> favoriteMovies = _favoriteMovies;
    favoriteMovies.remove(_movie!.id);

    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.set({
      'movies': favoriteMovies,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteMovies = favoriteMovies;
      _isFavorite = false;
    });
  }

  Future<void> isRecentlyWatched() async {
    final user = _firestore.collection(DB.recentlyWatched).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      Map<String, Map<String, dynamic>> recentlyWatched = ((data['movies'] ?? {}) as Map<dynamic, dynamic>).map<String, Map<String, dynamic>>((key, value) {
        return MapEntry(key, Map<String, dynamic>.from(value));
      });

      if (recentlyWatched.isNotEmpty) {
        bool isRecentlyWatched = recentlyWatched.keys.contains('${_movie!.id}');
        int? watchedProgress = recentlyWatched['${_movie!.id}']?['progress'];

        setState(() {
          _isRecentlyWatched = isRecentlyWatched;
          _watchedProgress = watchedProgress;
        });
      }
    }, onError: (e) => print("Error getting user: $e"));
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

  Future<void> getMovieDuration() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getMovieDetails(_movie!.id));

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      Map<String, dynamic> details = json.decode(response) as Map<String, dynamic>;
      int duration = details['runtime'];
      setState(() => _movie!.duration = duration);
    } else {
      print('Failed to get movie duration');
    }
  }

  Future<void> getMovieStreamUrl() async {
    Extractor extractor = Extractor(movie: _movie);
    String? streamUrl = await extractor.getStream();
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
    _fromFavorites = widget.fromFavorites;
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

  Widget WatchedProgress() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: LinearProgressIndicator(
          value: _watchedProgress! / (_movie!.duration! * 60),
          valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(.2),
        ),
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
            destination: Player(
              id: _movie!.id,
              title: _movie!.title,
              streamUrl: _movie!.streamUrl!,
              pageType: PageType.movies,
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
          Container(
            width: double.infinity,
            child: Text(
              'Cast',
              style: Theme.of(context).textTheme.titleSmall,
            ),
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

  Widget Category(String title, {required List<model.Movie> movies}) {
    movies = movies.length > 10 ? movies.sublist(0, 10) : movies;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != movies ? 18 : 0),
                  child: MovieCard(movies[index]),
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
                  onTap: () => navigate(destination: Movie(movie)),
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
        leading: BackButton(
          onPressed: () {
            if (_fromFavorites! && !_isFavorite) {
              navigate(destination: Fragments(initialPageIndex: 2), goingBack: true);
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
          color: Theme.of(context).primaryColor,
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
                      if (_isRecentlyWatched!) WatchedProgress(),
                      Play(),
                      Overview(),
                      Cast(),
                      if (_movie!.recommendations!.isNotEmpty) Category('Recommendations', movies: _movie!.recommendations!),
                      if (_movie!.similar!.isNotEmpty) Category('Similar', movies: _movie!.similar!),
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