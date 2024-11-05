import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:semo/models/genre.dart' as model;
import 'package:semo/models/movie.dart' as model;
import 'package:semo/models/search_results.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/movie.dart';
import 'package:semo/tv_show.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/urls.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

//ignore: must_be_immutable
class Genre extends StatefulWidget {
  model.Genre genre;
  PageType pageType;

  Genre({
    required this.genre,
    required this.pageType,
  });

  @override
  _GenreState createState() => _GenreState();
}

class _GenreState extends State<Genre> {
  model.Genre? _genre;
  PageType? _pageType;
  model.SearchResults _searchResults = model.SearchResults(page: 0, totalPages: 0, totalResults: 0);
  PagingController _pagingController = PagingController(firstPageKey: 0);

  navigate({required Widget destination, bool replace = false}) async {
    SwipeablePageRoute pageTransition = SwipeablePageRoute(
      canOnlySwipeFromEdge: true,
      builder: (BuildContext context) => destination,
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

  getContent(int pageKey) async {
    Map<String, dynamic> parameters = {
      'page': '${_searchResults.page + 1}',
      'with_genres': '${_genre!.id}',
    };
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    String url = _pageType! == PageType.movies ? Urls.discoverMovie : Urls.discoverTvShow;
    Uri uri = Uri.parse(url).replace(queryParameters: parameters);

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      model.SearchResults searchResults = model.SearchResults.fromJson(
        _pageType!,
        json.decode(response),
      );

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

      setState(() => _searchResults = searchResults);
    } else {
      _pagingController.error = 'error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to get movies',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
      );
    }
  }

  @override
  void initState() {
    _genre = widget.genre;
    _pageType = widget.pageType;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Genre - ${_genre!.id}',
      );
    });
    _pagingController.addPageRequestListener((pageKey) => getContent(pageKey));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
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
            errorWidget: (context, url, error) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.error, color: Colors.white54),
                ),
              );
            },
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
          ),
        ),
      ),
    );
  }
}