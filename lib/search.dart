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
import 'package:semo/tv_show.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/movie.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/search_results.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
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
  PagingController _pagingController = PagingController(firstPageKey: 0);

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

    String url = _pageType == PageType.movies ? Urls.searchMovies : Urls.searchTvShows;

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
          _pagingController.appendLastPage(searchResults.movies!);
        } else {
          int nextPageKey = pageKey + searchResults.movies!.length;
          _pagingController.appendPage(searchResults.movies!, nextPageKey);
        }
      } else {
        if (isLastPage) {
          _pagingController.appendLastPage(searchResults.tvShows!);
        } else {
          int nextPageKey = pageKey + searchResults.tvShows!.length;
          _pagingController.appendPage(searchResults.tvShows!, nextPageKey);
        }
      }
    } else {
      _pagingController.error = 'error';
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
    _pagingController.dispose();
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
          hintText: 'Type here...',
          hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
          border: InputBorder.none,
        ),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            FocusManager.instance.primaryFocus?.unfocus();

            if (_isFirstSearch) setState(() => _isFirstSearch = false);

            _pagingController.addPageRequestListener((pageKey) {
              search(
                query: query,
                pageKey: pageKey,
              );
            });
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

    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: posterUrl,
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
                      navigate(destination: Movie(movie!));
                    } else {
                      navigate(destination: TvShow(tvShow!));
                    }
                  },
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
            title,
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
            releaseDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget SearchResults() {
    if (_isFirstSearch) return Container();

    return PagedGridView(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate(
        itemBuilder: (context, media, index) {
          if (_pageType == PageType.movies) {
            return ResultCard(movie: media as model.Movie);
          } else {
            return ResultCard(tvShow: media as model.TvShow);
          }
        },
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        childAspectRatio: 1/2,
      ),
    );
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