import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:semo/models/person.dart' as model;
import 'package:semo/models/tv_show.dart' as model;
import 'package:semo/player.dart';
import 'package:semo/utils/api_keys.dart';
import 'package:semo/utils/db_names.dart';
import 'package:semo/utils/enums.dart';
import 'package:semo/utils/extractor.dart';
import 'package:semo/utils/spinner.dart';
import 'package:semo/utils/urls.dart';
import 'package:url_launcher/url_launcher.dart';

//ignore: must_be_immutable
class TvShow extends StatefulWidget {
  model.TvShow tvShow;

  TvShow(this.tvShow);

  @override
  _TvShowState createState() => _TvShowState();
}

class _TvShowState extends State<TvShow> {
  model.TvShow? _tvShow;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  List<int> _favoriteTvShows = [];
  late Spinner _spinner;
  bool _isLoading = true;
  int _currentSeason = 0;

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
      ).then((parameters) async {
        await Future.delayed(Duration(seconds: 1));
        if (parameters != null) {
          refresh(
            episodeId: parameters['episodeId'],
            watchedProgress: parameters['progress'],
          );
        };
      });
    }
  }

  getTvShowDetails({bool reload = false}) async {
    if (!reload) _spinner.show();
    await Future.wait([
      isFavorite(),
      getSeasons(),
      getTrailerUrl(),
      getCast(),
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
      List<int> favoriteTvShows = ((data['tv_shows'] ?? []) as List<dynamic>).cast<int>();

      if (favoriteTvShows.isNotEmpty) {
        setState(() {
          _isFavorite = favoriteTvShows.contains(_tvShow!.id);
          _favoriteTvShows = favoriteTvShows;
        });
      }
    }, onError: (e) => print("Error getting user: $e"));
  }

  addToFavorites() async {
    List<int> favoriteTvShows = _favoriteTvShows;
    favoriteTvShows.add(_tvShow!.id);

    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.set({
      'tv_shows': favoriteTvShows,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteTvShows = favoriteTvShows;
      _isFavorite = true;
    });
  }

  removeFromFavorites() async {
    List<int> favoriteTvShows = _favoriteTvShows;
    favoriteTvShows.remove(_tvShow!.id);

    final user = _firestore.collection(DB.favorites).doc(_auth.currentUser!.uid);
    await user.set({
      'tv_shows': favoriteTvShows,
    }, SetOptions(merge: true));

    setState(() {
      _favoriteTvShows = favoriteTvShows;
      _isFavorite = false;
    });
  }

  Future<void> getSeasons() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowDetails(_tvShow!.id));
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List<Map<String, dynamic>> seasonsData = (json.decode(response)['seasons'] as List<dynamic>).cast<Map<String, dynamic>>();

      List<model.Season> seasons = [];

      for (Map<String, dynamic> seasonData in seasonsData) {
        model.Season season = model.Season.fromJson(seasonData);

        if (season.number > 0) {
          if (season.airDate != null) {
            if (season.number == (_currentSeason + 1)) {
              List<model.Episode> episodes = await getEpisodes(season);
              season.episodes = episodes;
            }

            seasons.add(season);
          }

          setState(() => _tvShow!.seasons = seasons);
        }
      }
    } else {
      print('Failed to get tv show seasons');
    }
  }

  Future<List<model.Episode>> getEpisodes(model.Season season) async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getEpisodes(_tvShow!.id, season.number));

    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List episodesData = json.decode(response)['episodes'] as List;
      List<model.Episode> episodes = [];

      for (var episodeData in episodesData) {
        model.Episode episode = model.Episode.fromJson(episodeData);
        if (episode.airDate != null) episodes.add(episode);
      }

      Map<String, Map<String, dynamic>>? recentlyWatched = await getRecentlyWatched(season.id);

      if (recentlyWatched != null) {
        for (model.Episode episode in episodes) {
          if (recentlyWatched.keys.contains('${episode.id}')) {
            Map<String, dynamic> episodeDetails = recentlyWatched['${episode.id}'] as Map<String, dynamic>;
            episode.isRecentlyWatched = true;
            episode.watchedProgress = episodeDetails['progress'] ?? 0;
          }
        }
      }

      return episodes;
    } else {
      print('Failed to get tv show episodes');
    }

    return [];
  }

  Future<Map<String, Map<String, dynamic>>?> getRecentlyWatched(int seasonId) async {
    Map<String, Map<String, dynamic>>? results;

    final user = _firestore.collection(DB.recentlyWatched).doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
      Map<dynamic, dynamic> data = (doc.data() ?? {}) as Map<dynamic, dynamic>;
      Map<String, dynamic> recentlyWatched = (data['tv_shows'] ?? {}) as Map<String, dynamic>;

      if (recentlyWatched.keys.contains('${_tvShow!.id}')) {
        Map<String, Map<String, dynamic>> seasons = ((recentlyWatched['${_tvShow!.id}'] ?? {}) as Map<dynamic, dynamic>).map<String, Map<String, dynamic>>((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });

        if (seasons.keys.contains('$seasonId')) {
          Map<String, Map<String, dynamic>> season = ((seasons['$seasonId'] ?? {}) as Map<dynamic, dynamic>).map<String, Map<String, dynamic>>((key, value) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          });

          results = season;
        }
      }
    }, onError: (e) => print("Error getting user: $e"));

    return results;
  }

  Future<void> getTrailerUrl() async {
    String youtubeId = '';

    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowVideosUrl(_tvShow!.id));

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
      if (youtubeVideos.isNotEmpty) {
        youtubeVideos.sort((a, b) => b['size'].compareTo(a['size']));
        youtubeId = youtubeVideos[0]['key'] ?? '';
      }
    } else {
      print('Failed to get trailer youtube url');
    }

    String youtubeUrl = 'https://www.youtube.com/watch?v=$youtubeId';
    setState(() => _tvShow!.trailerUrl = youtubeUrl);
  }

  Future<void> getCast() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowCast(_tvShow!.id));

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

      setState(() => _tvShow!.cast = cast);
    } else {
      print('Failed to get tv show cast');
    }
  }

  Future<void> getRecommendations() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowRecommendations(_tvShow!.id));
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['results'] as List;
      List<model.TvShow> recommendations = data.map((json) => model.TvShow.fromJson(json)).toList();
      setState(() => _tvShow!.recommendations = recommendations);
    } else {
      print('Failed to get tv show recommendations');
    }
  }

  Future<void> getSimilar() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${APIKeys.tmdbAccessTokenAuth}',
    };

    Uri uri = Uri.parse(Urls.getTvShowSimilar(_tvShow!.id));
    Response request = await http.get(
      uri,
      headers: headers,
    );

    String response = request.body;
    if (!kReleaseMode) print(response);

    if (response.isNotEmpty) {
      List data = json.decode(response)['results'] as List;
      List<model.TvShow> similar = data.map((json) => model.TvShow.fromJson(json)).toList();
      setState(() => _tvShow!.similar = similar);
    } else {
      print('Failed to get similar tv shows');
    }
  }

  getStreamUrl(model.Episode episode) async {
    Extractor extractor = Extractor(episode: episode);
    String? streamUrl = await extractor.getStream();
    return streamUrl;
  }

  getSubtitles(model.Episode episode) async {
    List<File> srtFiles = [];

    try {
      Map<String, dynamic> parameters = {
        'api_key': APIKeys.subdl,
        'tmdb_id': '${_tvShow!.id}',
        'season_number': '${episode.season}',
        'episode_number': '${episode.number}',
        'languages': 'EN'
      };

      Uri uri = Uri.parse(Urls.subtitles).replace(
        queryParameters: parameters,
      );
      final response = await http.get(uri);

      if (!kReleaseMode) print(response.body);

      if (response.statusCode == 200) {
        final subtitlesData = jsonDecode(response.body);

        List subtitles = subtitlesData['subtitles'];

        Directory directory = await getTemporaryDirectory();
        String destinationDirectory = directory.path;

        for (var subtitle in subtitles) {
          String zipUrl = subtitle['url'];
          String fullZipUrl = Urls.subdlDownloadBase + '$zipUrl';

          final zipResponse = await http.get(Uri.parse(fullZipUrl));

          if (zipResponse.statusCode == 200) {
            final bytes = zipResponse.bodyBytes;
            final archive = ZipDecoder().decodeBytes(bytes);

            for (final file in archive) {
              if (file.isFile) {
                String fileName = file.name;
                String extension = path.extension(fileName);

                if (extension == '.srt') {
                  final data = file.content as List<int>;

                  File srtFile = File('$destinationDirectory/$fileName');
                  await srtFile.writeAsBytes(data);

                  srtFiles.add(srtFile);
                }
              }
            }
          } else {
            print('Failed to download subtitle ZIP: ${zipResponse.statusCode}');
          }
        }
      } else {
        print('Failed to fetch subtitles from API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }

    return srtFiles;
  }

  refresh({required int episodeId, required int watchedProgress}) async {
    for(model.Episode episode in _tvShow!.seasons![_currentSeason].episodes!) {
      if (episode.id == episodeId) {
        setState(() {
          episode.isRecentlyWatched = true;
          episode.watchedProgress = watchedProgress;
        });
      }
    }
  }

  @override
  void initState() {
    _tvShow = widget.tvShow;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _spinner = Spinner(context);
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'TV Show - ${_tvShow!.name}',
      );
      await getTvShowDetails();
    });
  }

  Widget TrailerPoster() {
    return CachedNetworkImage(
      imageUrl: Urls.getBestImageUrl(context) + _tvShow!.backdropPath,
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
                        Uri.parse(_tvShow!.trailerUrl!),
                        mode: LaunchMode.externalNonBrowserApplication,
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
        _tvShow!.name,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget FirstAirYear() {
    String firstAirYear = _tvShow!.firstAirDate.split('-')[0];
    return Container(
      width: double.infinity,
      child: Text(
        firstAirYear,
        style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget Overview() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20),
      child: Text(
        _tvShow!.overview,
        style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget Seasons() {
    model.Season season = _tvShow!.seasons![_currentSeason];
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Row(
            children: [
              DropdownMenu<model.Season>(
                initialSelection: season,
                requestFocusOnTap: false,
                enableFilter: false,
                enableSearch: false,
                textStyle: Theme.of(context).textTheme.displayLarge,
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSelected: (model.Season? season) async {
                  if (season != null) {
                    if (season.episodes == null) {
                      _spinner.show();

                      List<model.Episode> episodes = await getEpisodes(season);
                      int seasonIndex = _tvShow!.seasons!.indexOf(season);

                      setState(() => _tvShow!.seasons![seasonIndex].episodes = episodes);

                      _spinner.dismiss();
                    }

                    setState(() => _currentSeason = _tvShow!.seasons!.indexOf(season));
                  }
                },
                dropdownMenuEntries: _tvShow!.seasons!.map<DropdownMenuEntry<model.Season>>((model.Season season) {
                  return DropdownMenuEntry<model.Season>(
                    value: season,
                    label: season.name,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  );
                }).toList(),
              ),
              Spacer(),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: season.episodes!.length,
              itemBuilder: (context, index) => Episode(season, season.episodes![index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget Episode(model.Season season, model.Episode episode) {
    return InkWell(
      onTap: () async {
        _spinner.show();
        String? streamUrl = await getStreamUrl(episode);
        List<File>? subtitles = await getSubtitles(episode);
        _spinner.dismiss();

        if (streamUrl != null) {
          navigate(
            destination: Player(
              id: _tvShow!.id,
              seasonId: season.id,
              episodeId: episode.id,
              title: episode.name,
              streamUrl: streamUrl,
              subtitles: subtitles,
              pageType: PageType.tv_shows,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: Urls.getBestImageUrl(context) + episode.stillPath,
                  placeholder: (context, url) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  },
                  imageBuilder: (context, image) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: image,
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: episode.isRecentlyWatched ? Column(
                              children: [
                                Spacer(),
                                LinearProgressIndicator(
                                  value: episode.watchedProgress! / (episode.duration * 60),
                                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                                  backgroundColor: Colors.transparent,
                                ),
                              ],
                            ) : Container(),
                          ),
                        ),
                      ),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      width: MediaQuery.of(context).size.width * .3,
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      episode.name,
                      style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 3,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 18),
              child: Text(
                episode.overview,
                style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget Cast() {
    List<model.Person>? cast = _tvShow!.cast != null ? _tvShow!.cast!.length > 10 ? _tvShow!.cast!.sublist(0, 10) : _tvShow!.cast : [];

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
          if (_tvShow!.cast != null) Container(
            height: MediaQuery.of(context).size.height * 0.25,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cast!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != cast.length ? 18 : 0),
                  child: PersonCard(_tvShow!.cast![index]),
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

  Widget Category(String title, {required List<model.TvShow> tvShows}) {
    tvShows = tvShows.length > 10 ? tvShows.sublist(0, 10) : tvShows;

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
              itemCount: tvShows.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: (index + 1) != tvShows ? 18 : 0),
                  child: TvShowCard(tvShows[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget TvShowCard(model.TvShow tvShow) {
    List<String> firstAirContent = tvShow.firstAirDate.split('-');
    String firstAirYear = firstAirContent[0];

    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: '${Urls.imageBase_w185}${tvShow.posterPath}',
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
                              '${tvShow.voteAverage}',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                    ],
                  ),
                  onTap: () => navigate(destination: TvShow(tvShow)),
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
            tvShow.name,
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
            firstAirYear,
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
          onPressed: () => Navigator.pop(context, 'refresh'),
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
          onRefresh: () async {
            setState(() {
              _isLoading = true;
              _isFavorite = false;
              _tvShow!.trailerUrl = null;
              _tvShow!.cast = null;
              _tvShow!.recommendations = null;
              _tvShow!.similar = null;
            });
            getTvShowDetails(reload: true);
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
                      FirstAirYear(),
                      Overview(),
                      Seasons(),
                      Cast(),
                      if (_tvShow!.recommendations!.isNotEmpty) Category('Recommendations', tvShows: _tvShow!.recommendations!),
                      if (_tvShow!.similar!.isNotEmpty) Category('Similar', tvShows: _tvShow!.similar!),
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