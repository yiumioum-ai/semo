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
import 'package:semo/utils/api_keys.dart';
import 'package:semo/movie.dart';
import 'package:semo/models/media.dart' as model;
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/urls.dart';

//ignore: must_be_immutable
class Search extends StatefulWidget {
  PageType pageType;
  Search({
    required this.pageType,
  });
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  bool _isFirstSearch = true;
  PageType? _pageType;
  FocusNode _searchFocusNode = FocusNode();
  model.SearchResults _searchResults = model.SearchResults(
    page: 0,
    totalPages: 0,
    totalResults: 0
  );
  PagingController<int, model.Movie> _moviesPagingController = PagingController(firstPageKey: 0);
  PagingController<int, model.TvShow> _tvShowsPagingController = PagingController(firstPageKey: 0);
  String? oldQuery;

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

  search({required String query, required int pageKey}) async {
    Map<String, dynamic> parameters = {
      'query': query,
      'include_adult': 'false',
      'page': pageKey == 0 ? '1' : '${_searchResults.page + 1}',
    };
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    print(pageKey == 0 ? '1' : '${_searchResults.page + 1}');

    String url = Urls.search;

    if (_pageType == PageType.movies) {
      url += '/movie';
    } else {
      url += '/tv';
    }

    Uri uri = Uri.parse(url).replace(
      queryParameters: parameters,
    );

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      model.SearchResults searchResults = model.SearchResults.fromJson(
          _pageType!,
          json.decode(response)
      );

      setState(() => _searchResults = searchResults);

      bool isLastPage = pageKey == searchResults.totalResults;

      if (_pageType == PageType.movies) {
        if (isLastPage) {
          _moviesPagingController.appendLastPage(searchResults.movies!);
        } else {
          int nextPageKey = pageKey + searchResults.movies!.length;
          _moviesPagingController.appendPage(searchResults.movies!, nextPageKey);
        }
      } else {
        if (isLastPage) {
          _tvShowsPagingController.appendLastPage(searchResults.tvShows!);
        } else {
          int nextPageKey = pageKey + searchResults.tvShows!.length;
          _tvShowsPagingController.appendPage(searchResults.tvShows!, nextPageKey);
        }
      }
    } else {
      if (_pageType == PageType.movies) {
        _moviesPagingController.error = 'error';
      } else {
        _tvShowsPagingController.error = 'error';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _pageType = widget.pageType);

      FocusScope.of(context).requestFocus(_searchFocusNode);

      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Search',
      );
    });
  }

  @override
  void dispose() {
    _moviesPagingController.dispose();
    _tvShowsPagingController.dispose();
    super.dispose();
  }

  AppBar SearchAppBar() {
    return AppBar(
      leading: BackButton(),
      title: TextField(
        focusNode: _searchFocusNode,
        readOnly: !_isFirstSearch,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: Theme.of(context).textTheme.displayMedium,
        decoration: InputDecoration(
          hintText: 'Type in the movie or show name...',
          hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
          border: InputBorder.none,
        ),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            FocusManager.instance.primaryFocus?.unfocus();

            if (_isFirstSearch) setState(() => _isFirstSearch = false);

            if (_pageType == PageType.movies) {
              _moviesPagingController.addPageRequestListener((pageKey) {
                search(
                  query: query,
                  pageKey: pageKey,
                );
              });
            } else {
              _tvShowsPagingController.addPageRequestListener((pageKey) {
                search(
                  query: query,
                  pageKey: pageKey,
                );
              });
            }
          }
        },
      )
    );
  }

  Widget ResultCard({model.Movie? movie, model.TvShow? tvShow}) {
    String posterUrl, title, releaseDate;
    double voteAverage;

    if (_pageType == PageType.movies) {
      posterUrl = '${Urls.imageBase_w185}${movie!.posterPath}';
      title = movie.title;
      releaseDate = movie.releaseDate;
      voteAverage = movie.voteAverage;
    } else {
      posterUrl = '${Urls.imageBase_w185}${tvShow!.posterPath}';
      title = tvShow.name;
      releaseDate = tvShow.firstAirDate;
      voteAverage = tvShow.voteAverage;
    }

    List<String> releaseDateContent = releaseDate.split('-');
    releaseDate = releaseDateContent[0];

    voteAverage = double.parse(voteAverage.toStringAsFixed(1));

    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: posterUrl,
            placeholder: (context, url) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
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
                              '$voteAverage',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                    ],
                  ),
                  onTap: () {
                    if (_pageType == PageType.movies) {
                      navigate(
                        destination: Movie(movie: movie!),
                      );
                    } else {
                      /*navigate(
                        destination: TvShow(tvShow: tvShow),
                      );*/
                    }
                  },
                ),
              );
            },
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 10),
          child: Text(
            title,
            maxLines: 2,
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
            releaseDate,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget SearchResults() {
    SliverGridDelegate gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      childAspectRatio: 1/2,
    );

    late PagedGridView grid;
    if (_pageType == PageType.movies) {
      grid = PagedGridView<int, model.Movie>(
        pagingController: _moviesPagingController,
        builderDelegate: PagedChildBuilderDelegate<model.Movie>(
          itemBuilder: (context, movie, index) {
            return ResultCard(movie: movie);
          },
        ),
        gridDelegate: gridDelegate,
      );
    } else {
      grid = PagedGridView<int, model.TvShow>(
        pagingController: _tvShowsPagingController,
        builderDelegate: PagedChildBuilderDelegate<model.TvShow>(
          itemBuilder: (context, tvShow, index) {
            return ResultCard(tvShow: tvShow);
          },
        ),
        gridDelegate: gridDelegate,
      );
    }

    if (_isFirstSearch) return Container();

    return grid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _pageType != null ? SearchAppBar() : null,
      body: SafeArea(
        child: _pageType != null ? Container(
          padding: EdgeInsets.all(18),
          child: SearchResults(),
        ) : Container(),
      ),
    );
  }
}