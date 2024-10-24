import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/models/genre.dart' as model;
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/search_results.dart' as model;
import 'package:semo/movie.dart';
import 'package:semo/genre.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/pop_up_menu.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Movies extends StatefulWidget {
  @override
  _MoviesState createState() => _MoviesState();
}

class _MoviesState extends State<Movies> {
  List<model.Movie> _nowPlaying = [], _recentlyWatched = [];
  Map<String, Map<String, dynamic>>? _rawRecentlyWatched;
  CarouselSliderController _nowPlayingController = CarouselSliderController();
  int _currentNowPlayingIndex = 0;
  List<model.Genre> _genres = [];
  model.SearchResults _trendingResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
  model.SearchResults _popularResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
  model.SearchResults _topRatedResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
  PagingController<int, model.Movie> _trendingPagingController = PagingController(firstPageKey: 0);
  PagingController<int, model.Movie> _popularPagingController = PagingController(firstPageKey: 0);
  PagingController<int, model.Movie> _topRatedPagingController = PagingController(firstPageKey: 0);
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  late Spinner _spinner;
  bool _isLoading = true;

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
      ).then((action) async {
        await Future.delayed(Duration(seconds: 1));
        if (action == 'refresh') getRecentlyWatched();
      });
    }
  }

  getCategories({bool reload = false}) async {
    if (!reload) _spinner.show();
    _trendingPagingController.addPageRequestListener((pageKey) async {
      model.SearchResults searchResults = await getMovies(Urls.trendingMovies, pageKey: pageKey, resultsModel: _trendingResults, pagingController: _trendingPagingController);
      setState(() => _trendingResults = searchResults);
    });
    _popularPagingController.addPageRequestListener((pageKey) async {
      model.SearchResults searchResults = await getMovies(Urls.popularMovies, pageKey: pageKey, resultsModel: _popularResults, pagingController: _popularPagingController);
      setState(() => _popularResults = searchResults);
    });
    _topRatedPagingController.addPageRequestListener((pageKey) async {
      model.SearchResults searchResults = await getMovies(Urls.topRatedMovies, pageKey: pageKey, resultsModel: _topRatedResults, pagingController: _topRatedPagingController);
      setState(() => _topRatedResults = searchResults);
    });
    await Future.wait([
      getNowPlaying(),
      getRecentlyWatched(),
      getGenres(),
    ]);
    setState(() => _isLoading = false);
    if (!reload) _spinner.dismiss();
  }

  Future<void> getNowPlaying() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.nowPlayingMovies);
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['results'] as List;
      List<model.Movie> nowPlaying = data.map((json) => model.Movie.fromJson(json)).toList();

      setState(() => _nowPlaying = nowPlaying.length > 10 ? nowPlaying.sublist(0, 10) : nowPlaying);
    } else {
      print('Error getting now playing movies');
    }
  }

  Future<model.SearchResults> getMovies(String url, {required int pageKey, required model.SearchResults resultsModel, required PagingController pagingController}) async {
    Map<String, dynamic> parameters = {
      'page': '${resultsModel.page + 1}',
    };
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(url).replace(queryParameters: parameters);

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      model.SearchResults searchResults = model.SearchResults.fromJson(
        PageType.movies,
        json.decode(response),
      );

      bool isLastPage = pageKey == searchResults.totalResults;

      if (isLastPage) {
        pagingController.appendLastPage(searchResults.movies!);
      } else {
        int nextPageKey = pageKey + searchResults.movies!.length;
        pagingController.appendPage(searchResults.movies!, nextPageKey);
      }

      return searchResults;
    } else {
      pagingController.error = 'error';
      return resultsModel;
    }
  }

  Map<String, Map<String, dynamic>> sortRecentlyWatched(Map<String, Map<String, dynamic>> rawRecentlyWatched) {
    List<MapEntry<String, Map<String, dynamic>>> entries = rawRecentlyWatched.entries.toList();

    entries.sort((a, b) {
      int timestampA = a.value['timestamp'] ?? 0;
      int timestampB = b.value['timestamp'] ?? 0;
      return timestampB.compareTo(timestampA);
    });

    Map<String, Map<String, dynamic>> sortedRecentlyWatched = Map.fromEntries(entries);

    return sortedRecentlyWatched;
  }

  Future<void> getRecentlyWatched() async {
    final user = _firestore.collection(DB.recentlyWatched).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      Map<String, Map<String, dynamic>> rawRecentlyWatched = ((data['movies'] ?? {}) as Map<dynamic, dynamic>).map<String, Map<String, dynamic>>((key, value) {
        return MapEntry(key, Map<String, dynamic>.from(value));
      });
      rawRecentlyWatched = sortRecentlyWatched(rawRecentlyWatched);

      for (String id in rawRecentlyWatched.keys) getMovieDetails(int.parse(id));
      setState(() {
        _rawRecentlyWatched = {};
        _rawRecentlyWatched = rawRecentlyWatched;
      });
    }, onError: (e) => print("Error getting user: $e"));
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
      setState(() => _recentlyWatched.add(movie));
    } else {
      print('Failed to get movie details: $id');
    }
  }

  Future<void> getGenres() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.movieGenres).replace();

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['genres'] as List;
      List<model.Genre> genres = data.map((json) => model.Genre.fromJson(json)).toList();
      setState(() => _genres = genres);
    } else {
      print('Failed to get genres');
    }
  }

  removeFromRecentlyWatched(model.Movie movie) async {
    Map<String, Map<String, dynamic>> rawRecentlyWatched = _rawRecentlyWatched!;
    rawRecentlyWatched.removeWhere((id, value) => id == movie.id);

    final user = _firestore.collection(DB.recentlyWatched).doc(_auth.currentUser!.uid);
    await user.set({
      'movies': rawRecentlyWatched,
    }, SetOptions(merge: true));

    setState(() {
      _recentlyWatched.remove(movie);
      _rawRecentlyWatched = rawRecentlyWatched;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Movies',
      );
      getCategories();
    });
  }

  @override
  void dispose() {
    _trendingPagingController.dispose();
    _popularPagingController.dispose();
    _topRatedPagingController.dispose();
    super.dispose();
  }

  Widget NowPlaying(List<model.Movie> movies) {
    return Column(
      children: [
        Container(
          child: CarouselSlider.builder(
            carouselController: _nowPlayingController,
            itemCount: movies.length,
            options: CarouselOptions(
              aspectRatio: 2,
              autoPlay: true,
              enlargeCenterPage: true,
              onPageChanged: (int index, CarouselPageChangedReason reason) => setState(() => _currentNowPlayingIndex = index),
            ),
            itemBuilder: (context, index, realIndex) => MoviePoster(movies[index]),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 20),
          child: AnimatedSmoothIndicator(
            activeIndex: _currentNowPlayingIndex,
            count: movies.length,
            effect: ExpandingDotsEffect(
              dotWidth: 10,
              dotHeight: 10,
              dotColor: Colors.white30,
              activeDotColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget MoviePoster(model.Movie movie) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              child: CachedNetworkImage(
                imageUrl: '${Urls.getBestImageUrl(context)}${movie.backdropPath}',
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor),
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor),
                    child: Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.transparent,
                    Theme.of(context).primaryColor.withOpacity(.1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                children: [
                  Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 14,
                      bottom: 8,
                    ),
                    child: Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  navigate(destination: Movie(movie));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget Category(String title, {PagingController? pagingController, List<model.Movie>? movies}) {
    Widget titleContainer = Container(
      width: double.infinity,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
    late Widget contentContainer;

    if (pagingController != null) {
      contentContainer = PagedListView(
        pagingController: pagingController,
        scrollDirection: Axis.horizontal,
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, movie, index) {
            return Container(
              margin: EdgeInsets.only(right: (index + 1) != pagingController.nextPageKey ? 18 : 0),
              child: MovieCard(movie as model.Movie),
            );
          },
        ),
      );
    } else {
      contentContainer = ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies!.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: (index + 1) != movies.length ? 18 : 0),
            child: MovieCard(movies[index], recentlyWatched: true),
          );
        },
      );
    }

    return Container(
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          titleContainer,
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: contentContainer,
          ),
        ],
      ),
    );
  }

  Widget MovieCard(model.Movie movie, {bool recentlyWatched = false}) {
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
                child: PopupMenuContainer<String>(
                  items: recentlyWatched ? [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                  ] : null,
                  onItemSelected: (action) async {
                    if (action != null) {
                      if (action == 'remove') removeFromRecentlyWatched(movie);
                    }
                  },
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => navigate(destination: Movie(movie)),
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
                  ),
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
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          margin: EdgeInsets.only(top: 5),
          child: Text(
            releaseYear,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget Genres(List<model.Genre> genres) {
    return Container(
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Text(
              'Genres',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != genres.length ? 18 : 0),
                  child: GenreCard(genres[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget GenreCard(model.Genre genre) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(),
                onTap: () => navigate(
                  destination: Genre(genre: genre, pageType: PageType.movies),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 10),
            child: Text(
              genre.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: () async {
          _trendingPagingController.dispose();
          _popularPagingController.dispose();
          _topRatedPagingController.dispose();

          setState(() {
            _isLoading = true;
            _nowPlaying = [];
            _recentlyWatched = [];
            _genres = [];
            _trendingResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
            _popularResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
            _topRatedResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
            _trendingPagingController = PagingController(firstPageKey: 0);
            _popularPagingController = PagingController(firstPageKey: 0);
            _topRatedPagingController = PagingController(firstPageKey: 0);
          });
          getCategories(reload: true);
        },
        child: !_isLoading ? SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.all(18),
              child: Column(
                children: [
                  NowPlaying(_nowPlaying),
                  if (_recentlyWatched.isNotEmpty) Category('Recently watched', movies: _recentlyWatched),
                  Category('Trending', pagingController: _trendingPagingController),
                  Category('Popular', pagingController: _popularPagingController),
                  Category('Top rated', pagingController: _topRatedPagingController),
                  Genres(_genres),
                ],
              ),
            ),
          ),
        ) : Container(),
      ),
    );
  }
}