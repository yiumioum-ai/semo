import "dart:async";

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/favorites.dart";
import "package:semo/screens/landing.dart";
import "package:semo/models/navigation_page.dart";
import "package:semo/screens/movies.dart";
import "package:semo/screens/search.dart";
import "package:semo/screens/settings.dart";
import "package:semo/screens/tv_shows.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/navigation_helper.dart";

class Fragments extends StatefulWidget {
  const Fragments({
    super.key,
    this.initialPageIndex = 0,
    this.initialFavoritesTabIndex = 0,
  });
  
  final int initialPageIndex;
  final int initialFavoritesTabIndex;

  @override
  _FragmentsState createState() => _FragmentsState();
}

class _FragmentsState extends State<Fragments> with TickerProviderStateMixin {
  int _selectedPageIndex = 0;
  List<NavigationPage> _navigationPages = <NavigationPage>[];
  late TabController _tabController;
  late StreamSubscription<dynamic> _connectionSubscription;
  bool _isConnectedToInternet = true;

  void checkUserSession() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted && user == null) {
        NavigationHelper.navigate(
          context,
          Landing(),
          replace: true,
        );
      }
    });
  }

  void populatePages() {
    setState(() {
      _navigationPages = <NavigationPage>[
        NavigationPage(
          icon: Icons.movie,
          title: "Movies",
          widget: const Movies(),
          mediaType: MediaType.movies,
        ),
        NavigationPage(
          icon: Icons.video_library,
          title: "TV Shows",
          widget: const TvShows(),
          mediaType: MediaType.tvShows,
        ),
        NavigationPage(
          icon: Icons.favorite,
          title: "Favorites",
          widget: TabBarView(
            controller: _tabController,
            children: <Widget>[
              Favorites(mediaType: MediaType.movies),
              Favorites(mediaType: MediaType.tvShows),
            ],
          )
        ),
        NavigationPage(
          icon: Icons.settings,
          title: "Settings",
          widget: Settings()
        ),
      ];
    });
  }

  Future<void> initConnectivity() async {
    bool isConnectedToInternet = await InternetConnection().hasInternetAccess;
    setState(() => _isConnectedToInternet = isConnectedToInternet);

    _connectionSubscription = InternetConnection().onStatusChange.listen((InternetStatus status) async {
      if (mounted) {
        switch (status) {
          case InternetStatus.connected:
            setState(() => _isConnectedToInternet = true);
          case InternetStatus.disconnected:
            setState(() => _isConnectedToInternet = false);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initialPageIndex;
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialFavoritesTabIndex,
      vsync: this,
    );
    initConnectivity();
    checkUserSession();
    populatePages();
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  Widget NavigationTile(int index) => Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: ListTile(
        iconColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(.3),
        titleTextStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
          fontWeight: _selectedPageIndex == index ? FontWeight.w900 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        selected: _selectedPageIndex == index,
        leading: Icon(_navigationPages[index].icon),
        title: Container(
          padding: _selectedPageIndex == index ? const EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
          child: Text(_navigationPages[index].title),
        ),
        onTap: () {
          setState(() => _selectedPageIndex = index);
          Navigator.pop(context);
        },
      ),
    );

  Widget NoInternet() => Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.wifi_off_sharp,
            color: Colors.white54,
            size: 80,
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: Text(
              "You have lost internet connection",
              style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white54),
            ),
          ),
        ],
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(_navigationPages[_selectedPageIndex].title),
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: _isConnectedToInternet && _selectedPageIndex == 2 ? TabBar(
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
          (_isConnectedToInternet && _selectedPageIndex <= 1) ? IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              NavigationHelper.navigate(
                context,
                Search(mediaType: _navigationPages[_selectedPageIndex].mediaType),
              );
            },
          ) : Container(),
        ],
      ),
      body: _isConnectedToInternet ? _navigationPages[_selectedPageIndex].widget : NoInternet(),
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
              for (final (int index, _) in _navigationPages.indexed) NavigationTile(index),
            ],
          ),
        ),
      ),
    );
}