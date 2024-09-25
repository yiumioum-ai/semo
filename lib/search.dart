import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/api_keys.dart';
import 'package:semo/movie.dart';
import 'package:semo/models/movie.dart' as model;
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/urls.dart';

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
  late PageType _pageType;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  model.SearchResults _searchResults = model.SearchResults(
    page: 0,
    totalPages: 0,
    totalResults: 0,
    movies: [],
  );
  int _pageSize = 20;
  PagingController<int, model.Movie> _pagingController = PagingController(
    firstPageKey: 0,
  );

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

    Response request = await http.get(
      Urls.createUri(
        url: Urls.movieSearch,
        queryParameters: parameters,
      ),
      headers: headers,
    );

    String response = request.body;
    if (!Foundation.kReleaseMode) {
      print(response);
    }

    if (response != '[]' || response.isNotEmpty) {
      model.SearchResults searchResults = model.SearchResults.fromJson(
        json.decode(response),
      );

      setState(() {
        _searchResults = searchResults;
      });

      bool isLastPage = pageKey == searchResults.totalResults;
      if (isLastPage) {
        _pagingController.appendLastPage(searchResults.movies);
      } else {
        final nextPageKey = pageKey + searchResults.movies.length;
        _pagingController.appendPage(searchResults.movies, nextPageKey);
      }
    } else {
      _pagingController.error = 'error';
    }
  }

  @override
  void initState() {
    setState(() {
      _pageType = widget.pageType;
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: BackButton(
        color: Colors.white,
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: Theme.of(context).textTheme.displayMedium,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
            color: Colors.white54,
          ),
          border: InputBorder.none,
        ),
        onTapOutside: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            FocusManager.instance.primaryFocus?.unfocus();

            if (_isFirstSearch) {
              setState(() {
                _isFirstSearch = false;
              });
            }
            if (!_isFirstSearch) _pagingController.refresh();

            _pagingController.addPageRequestListener((pageKey) {
              search(
                query: query,
                pageKey: pageKey,
              );
            });
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () {
            _searchController.clear();
          },
        ),
      ],
    );
  }

  Widget MovieCard({required model.Movie movie}) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            child: CachedNetworkImage(
              imageUrl: '${Urls.imageBase_w185}${movie.posterPath}',
              placeholder: (context, url) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Icon(
                  Icons.error,
                );
              },
            ),
            onTap: () {
              navigate(
                destination: Movie(
                  movie: movie,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 5,
          ),
          child: Text(
            '${movie.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
      ],
    );
  }

  Widget MovieSearchResults() {
    Widget gridView = Container(
      padding: EdgeInsets.all(18),
      child: PagedGridView<int, model.Movie>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<model.Movie>(
          itemBuilder: (context,movie,index) {
            return MovieCard(
              movie: movie,
            );
          },
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          childAspectRatio: 1/2,
        ),
      ),
    );

    return _isFirstSearch ? Container() : gridView;
  }

  Widget TVShowSearchResults() {
    return Container(
      padding: EdgeInsets.all(18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: SearchAppBar(),
      body: SafeArea(
        child: _pageType == PageType.movies ? MovieSearchResults() : TVShowSearchResults(),
      ),
    );
  }
}