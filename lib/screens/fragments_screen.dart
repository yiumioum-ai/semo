import "dart:async";

import "package:flutter/material.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/favorites_screen.dart";
import "package:semo/models/fragment_screen.dart";
import "package:semo/screens/movies_screen.dart";
import "package:semo/screens/search_screen.dart";
import "package:semo/screens/settings_screen.dart";
import "package:semo/screens/tv_shows_screen.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/navigation_helper.dart";

class FragmentsScreen extends BaseScreen {
  const FragmentsScreen({
    super.key,
    this.initialPageIndex = 0,
    this.initialFavoritesTabIndex = 0,
  }) : super(shouldLogScreenView: false);
  
  final int initialPageIndex;
  final int initialFavoritesTabIndex;

  @override
  BaseScreenState<FragmentsScreen> createState() => _FragmentsScreenState();
}

class _FragmentsScreenState extends BaseScreenState<FragmentsScreen> with TickerProviderStateMixin {
  int _selectedPageIndex = 0;
  List<FragmentScreen> fragmentScreens = <FragmentScreen>[];
  late TabController _tabController;

  @override
  String get screenName => "Fragments";

  void _initFragments() {
    setState(() {
      fragmentScreens = <FragmentScreen>[
        const FragmentScreen(
          icon: Icons.movie,
          title: "Movies",
          widget: MoviesScreen(),
          mediaType: MediaType.movies,
        ),
        const FragmentScreen(
          icon: Icons.video_library,
          title: "TV Shows",
          widget: TvShowsScreen(),
          mediaType: MediaType.tvShows,
        ),
        FragmentScreen(
          icon: Icons.favorite,
          title: "Favorites",
          widget: TabBarView(
            controller: _tabController,
            children: const <Widget>[
              FavoritesScreen(mediaType: MediaType.movies),
              FavoritesScreen(mediaType: MediaType.tvShows),
            ],
          )
        ),
        FragmentScreen(
          icon: Icons.settings,
          title: "Settings",
          widget: SettingsScreen()
        ),
      ];
    });
  }

  @override
  Future<void> initializeScreen() async {
    _selectedPageIndex = widget.initialPageIndex;
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialFavoritesTabIndex,
      vsync: this,
    );
    _initFragments();
  }

  Widget _buildNavigationTile(int index) => Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 18,
    ),
    child: ListTile(
      iconColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: .3),
      titleTextStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
        fontWeight: _selectedPageIndex == index ? FontWeight.w900 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      selected: _selectedPageIndex == index,
      leading: Icon(fragmentScreens[index].icon),
      title: Container(
        padding: _selectedPageIndex == index ? const EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
        child: Text(fragmentScreens[index].title),
      ),
      onTap: () {
        setState(() => _selectedPageIndex = index);
        Navigator.pop(context);},
    ),
  );

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(fragmentScreens[_selectedPageIndex].title),
      leading: Builder(
        builder: (BuildContext context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      bottom: _selectedPageIndex == 2 ? TabBar(
        controller: _tabController,
        tabs: const <Tab>[
          Tab(
            icon: Icon(Icons.movie),
            text: "Movies",
          ),
          Tab(
            icon: Icon(Icons.video_library),
            text: "TV Shows",
          ),
        ],
      ) : null,
      actions: <Widget>[
        (isConnectedToInternet && _selectedPageIndex <= 1) ? IconButton(
          icon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            NavigationHelper.navigate(
              context,
              SearchScreen(mediaType: fragmentScreens[_selectedPageIndex].mediaType),
            );
          },
        ) : Container(),
      ],
    ),
    body: fragmentScreens[_selectedPageIndex].widget,
    drawer: SafeArea(
      top: true,
      left: true,
      right: true,
      bottom: false,
      child: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 200,
              child: Center(
                child: Assets.images.appIcon.image(
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Divider(color: Theme.of(context).cardColor),
            ),
            for (final (int index, _) in fragmentScreens.indexed) _buildNavigationTile(index),
          ],
        ),
      ),
    ),
  );
}