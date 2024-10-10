import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/urls.dart';

//ignore: must_be_immutable
class MovieGenre extends StatefulWidget {
  model.Genre genre;

  MovieGenre({
    required this.genre,
  });

  @override
  _MovieGenreState createState() => _MovieGenreState();
}

class _MovieGenreState extends State<MovieGenre> {
  model.Genre? _genre;
  model.SearchResults _searchResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
  PagingController<int, model.Movie> _pagingController = PagingController(firstPageKey: 0);

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

  getMovies(int pageKey) async {
    Map<String, dynamic> parameters = {
      'page': '${_searchResults.page + 1}',
      'with_genres': '${_genre!.id}',
    };
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.discoverMovie).replace(queryParameters: parameters);

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
        _pagingController.appendLastPage(searchResults.movies!);
      } else {
        int nextPageKey = pageKey + searchResults.movies!.length;
        _pagingController.appendPage(searchResults.movies!, nextPageKey);
      }

      setState(() => _searchResults = searchResults);
    } else {
      _pagingController.error = 'error';
    }
  }

  @override
  void initState() {
    _genre = widget.genre;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Movie Genre - ${_genre!.name}',
      );
    });
    _pagingController.addPageRequestListener((pageKey) => getMovies(pageKey));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
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
                  onTap: () => navigate(destination: Movie(movie: movie)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_genre!.name)),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(18),
          child: PagedGridView(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (context, movie, index) => MovieCard(movie as model.Movie),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              childAspectRatio: 1/2,
            ),
          ),
        ),
      ),
    );
  }
}