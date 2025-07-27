import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/episode_card.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/media_info.dart";
import "package:semo/components/media_poster.dart";
import "package:semo/components/person_card_horizontal_list.dart";
import "package:semo/components/season_selector.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/person.dart";
import "package:semo/models/search_results.dart";
import "package:semo/models/season.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/player_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/stream_extractor/extractor.dart";
import "package:semo/services/subtitle_service.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/enums/media_type.dart";

class TvShowScreen extends BaseScreen {
  const TvShowScreen(this.tvShow, {super.key});

  final TvShow tvShow;

  @override
  BaseScreenState<TvShowScreen> createState() => _TvShowScreenState();
}

class _TvShowScreenState extends BaseScreenState<TvShowScreen> {
  final TMDBService _tmdbService = TMDBService();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  final SubtitleService _subtitleService = SubtitleService();
  bool _isFavorite = false;
  bool _isLoading = true;
  int _currentSeasonIndex = 0;
  late final PagingController<int, TvShow> _recommendationsController = PagingController<int, TvShow>(
    getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getRecommendations(
        MediaType.tvShows,
        widget.tvShow.id,
        pageKey,
      );
      return results.tvShows ?? <TvShow>[];
    },
  );
  late final PagingController<int, TvShow> _similarController = PagingController<int, TvShow>(
    getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      final SearchResults results = await _tmdbService.getSimilar(
        MediaType.tvShows,
        widget.tvShow.id,
        pageKey,
      );
      return results.tvShows ?? <TvShow>[];
    },
  );

  Future<void> _loadTvShowDetails() async {
    try {
      await Future.wait(<Future<void>>[
        _loadSeasons(),
        _loadTrailer(),
        _loadCast(),
      ]);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load TV show details");
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSeasons() async {
    final List<Season> seasons = await _tmdbService.getTvShowSeasons(widget.tvShow.id);
    if (mounted && seasons.isNotEmpty) {
      setState(() => widget.tvShow.seasons = seasons);
      await _loadEpisodesForSeason(0);
    }
  }

  Future<void> _loadEpisodesForSeason(int seasonIndex) async {
    if (widget.tvShow.seasons == null || seasonIndex >= widget.tvShow.seasons!.length) {
      return;
    }

    try {
      final Season season = widget.tvShow.seasons![seasonIndex];
      if (season.episodes != null) {
        return;
      }

      if (!_isLoading) {
        spinner.show();
      }

      final List<Episode> episodes = await _tmdbService.getEpisodes(
        widget.tvShow.id,
        season.number,
        widget.tvShow.name,
      );
      final Map<String, Map<String, dynamic>>? recentlyWatchedEpisodes = await _recentlyWatchedService.getEpisodes(
        widget.tvShow.id,
        season.id,
      );

      if (recentlyWatchedEpisodes != null) {
        for (final Episode episode in episodes) {
          final Map<String, dynamic>? recentlyWatchedEpisodeData = recentlyWatchedEpisodes["${episode.id}"];

          if (recentlyWatchedEpisodeData != null) {
            episode.isRecentlyWatched = true;
            episode.watchedProgress = recentlyWatchedEpisodeData["progress"] ?? 0;
          }
        }
      }

      if (mounted) {
        setState(() => widget.tvShow.seasons![seasonIndex].episodes = episodes);
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load episodes");
      }
    }

    if (!_isLoading) {
      spinner.dismiss();
    }
  }

  Future<void> _loadTrailer() async {
    final String? url = await _tmdbService.getTrailerUrl(MediaType.tvShows, widget.tvShow.id);
    if (mounted) {
      setState(() => widget.tvShow.trailerUrl = url);
    }
  }

  Future<void> _loadCast() async {
    final List<Person> cast = await _tmdbService.getCast(MediaType.tvShows, widget.tvShow.id);
    if (mounted) {
      setState(() => widget.tvShow.cast = cast);
    }
  }

  void _toggleFavorite() {
    try {
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite
            ? RemoveFavorite(widget.tvShow, MediaType.tvShows)
            : AddFavorite(widget.tvShow, MediaType.tvShows);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _playEpisode(Episode episode) async {
    spinner.show();

    try {
      final Season season = widget.tvShow.seasons![_currentSeasonIndex];
      final MediaStream? stream = await StreamExtractor.getStream(episode: episode);

      if (stream != null && stream.url.isNotEmpty) {
        stream.subtitleFiles = await _subtitleService.getSubtitles(
          widget.tvShow.id,
          seasonNumber: episode.season,
          episodeNumber: episode.number,
        );

        spinner.dismiss();

        final dynamic result = await navigate(
          PlayerScreen(
            tmdbId: widget.tvShow.id,
            seasonId: season.id,
            episodeId: episode.id,
            title: episode.name,
            stream: stream,
            mediaType: MediaType.tvShows,
          ),
        );

        if (result != null) {
          _handlePlayerResult(result);
        }
      } else {
        if (mounted) {
          showSnackBar(context, "No stream found");
        }
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load stream");
      }
    }

    spinner.dismiss();
  }

  void _handlePlayerResult(Map<String, dynamic> result) {
    try {
      final int? episodeId = result["episodeId"] as int?;
      final int? progressSeconds = result["progress"] as int?;

      if (episodeId != null && progressSeconds != null) {
        final List<Episode>? episodes = widget.tvShow.seasons?[_currentSeasonIndex].episodes;
        final int? episodeIndex = episodes?.indexWhere((Episode episode) => episode.id == episodeId);

        if (episodes != null && episodeIndex != null && episodeIndex != -1) {
          if (mounted) {
            setState(() {
              episodes[episodeIndex].isRecentlyWatched = true;
              episodes[episodeIndex].watchedProgress = progressSeconds;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _markEpisodeAsWatched(Episode episode) async {
    try {
      final Season season = widget.tvShow.seasons![_currentSeasonIndex];

      unawaited(
        _recentlyWatchedService.updateEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
          episode.duration * 60,
        ),
      );
    } catch (_) {}

    setState(() {
      episode.isRecentlyWatched = true;
      episode.watchedProgress = episode.duration * 60;
    });
  }

  Future<void> _removeEpisodeFromRecentlyWatched(Episode episode) async {
    try {
      final Season season = widget.tvShow.seasons![_currentSeasonIndex];

      unawaited(
        _recentlyWatchedService.removeEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
        ),
      );
    } catch (_) {}

    setState(() {
      episode.isRecentlyWatched = false;
      episode.watchedProgress = null;
    });
  }

  Future<void> _onSeasonChanged(Season season) async {
    final int? selectedSeasonIndex = widget.tvShow.seasons?.indexOf(season);

    if (selectedSeasonIndex != null && selectedSeasonIndex != -1) {
      setState(() => _currentSeasonIndex = selectedSeasonIndex);
      if (season.episodes == null) {
        await _loadEpisodesForSeason(selectedSeasonIndex);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      widget.tvShow.trailerUrl = null;
      widget.tvShow.cast = null;
      widget.tvShow.seasons = null;
      _currentSeasonIndex = 0;
    });

    _recommendationsController.refresh();
    _similarController.refresh();

    await _loadTvShowDetails();
  }

  Widget _buildSeasonSelector() {
    if (widget.tvShow.seasons == null || widget.tvShow.seasons!.isEmpty) {
      return const SizedBox.shrink();
    }

    final Season selectedSeason = widget.tvShow.seasons![_currentSeasonIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SeasonSelector(
              seasons: widget.tvShow.seasons!,
              selectedSeason: selectedSeason,
              onSeasonChanged: _onSeasonChanged,
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedSeasonEpisodes() {
    if (widget.tvShow.seasons == null || widget.tvShow.seasons!.isEmpty) {
      return const SizedBox.shrink();
    }

    final Season selectedSeason = widget.tvShow.seasons![_currentSeasonIndex];

    if (selectedSeason.episodes == null) {
      return const Text("No episodes available for this season.");
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: selectedSeason.episodes!.length,
      itemBuilder: (BuildContext context, int index) {
        final Episode episode = selectedSeason.episodes![index];
        return EpisodeCard(
          episode: episode,
          onTap: () => _playEpisode(episode),
          onMarkWatched: () => _markEpisodeAsWatched(episode),
          onRemove: episode.isRecentlyWatched
              ? () => _removeEpisodeFromRecentlyWatched(episode)
              : null,
        );
      },
    );
  }

  Widget _buildPersonCardHorizontalList() {
    if (widget.tvShow.cast == null || widget.tvShow.cast!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: PersonCardHorizontalList(
        title: "Cast",
        people: widget.tvShow.cast!,
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({required PagingController<int, TvShow> controller, required String title}) => Padding(
    padding: const EdgeInsets.only(top: 30),
    child: MediaCardHorizontalList(
      title: title,
      pagingController: controller,
      mediaType: MediaType.tvShows,
      //ignore: avoid_annotating_with_dynamic
      onTap: (dynamic media) => navigate(
        TvShowScreen(media as TvShow),
      ),
    ),
  );

  @override
  String get screenName => "TV Show - ${widget.tvShow.name}";

  @override
  Future<void> initializeScreen() async {
    await _loadTvShowDetails();
  }

  @override
  void handleDispose() {
    _recommendationsController.dispose();
    _similarController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (mounted) {
        setState(() => _isFavorite = state.favoriteTvShows?.any((TvShow tvShow) => tvShow.id == widget.tvShow.id) ?? false);
      }

      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) => Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context, "refresh")),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            color: _isFavorite ? Colors.red : Colors.white,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: !_isLoading ? SingleChildScrollView(
            child: Column(
              children: <Widget>[
                MediaPoster(
                  backdropPath: widget.tvShow.backdropPath,
                  trailerUrl: widget.tvShow.trailerUrl,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MediaInfo(
                        title: widget.tvShow.name,
                        subtitle: "${widget.tvShow.firstAirDate.split("-")[0]} · ${widget.tvShow.seasons?.length ?? 1} Seasons",
                        overview: widget.tvShow.overview,
                      ),
                      const SizedBox(height: 30),
                      _buildSeasonSelector(),
                      const SizedBox(height: 30),
                      _buildSelectedSeasonEpisodes(),
                      _buildPersonCardHorizontalList(),
                      _buildMediaCardHorizontalList(
                        title: "Recommendations",
                        controller: _recommendationsController,
                      ),
                      _buildMediaCardHorizontalList(
                        title: "Similar",
                        controller: _similarController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ) : const Center(child: CircularProgressIndicator()),
        ),
      ),
    ),
  );
}
