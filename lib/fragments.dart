import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:semo/favorites.dart';
import 'package:semo/landing.dart';
import 'package:semo/models/navigation_page.dart';
import 'package:semo/movies.dart';
import 'package:semo/search.dart';
import 'package:semo/settings.dart';
import 'package:semo/tv_shows.dart';
import 'package:semo/utils/enums.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

//ignore: must_be_immutable
class Fragments extends StatefulWidget {
  int initialPageIndex, initialFavoritesTabIndex;

  Fragments({
    this.initialPageIndex = 0,
    this.initialFavoritesTabIndex = 0,
  });

  @override
  _FragmentsState createState() => _FragmentsState();
}

class _FragmentsState extends State<Fragments> with TickerProviderStateMixin {
  late int _selectedPageIndex;
  List<NavigationPage> _navigationPages = [];
  late TabController _tabController;

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

  checkUserSession() async {
    await FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        navigate(
          destination: Landing(),
          replace: true,
        );
      }
    });
  }

  populatePages() {
    _selectedPageIndex = widget.initialPageIndex;
    _tabController = TabController(length: 2, initialIndex: widget.initialFavoritesTabIndex, vsync: this);
    setState(() {
      _navigationPages = [
        NavigationPage(
          icon: Icons.movie,
          title: 'Movies',
          widget: Movies(),
          pageType: PageType.movies,
        ),
        NavigationPage(
          icon: Icons.video_library,
          title: 'TV Shows',
          widget: TvShows(),
          pageType: PageType.tv_shows,
        ),
        NavigationPage(
          icon: Icons.favorite,
          title: 'Favorites',
          widget: TabBarView(
            controller: _tabController,
            children: [
              Favorites(pageType: PageType.movies),
              Favorites(pageType: PageType.tv_shows),
            ],
          ),
          pageType: PageType.favorites,
        ),
        NavigationPage(
          icon: Icons.settings,
          title: 'Settings',
          widget: Settings(),
          pageType: PageType.settings,
        ),
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    checkUserSession();
    populatePages();
  }

  Widget NavigationTile(int index) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: ListTile(
        textColor: Colors.white,
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
          padding: _selectedPageIndex == index ? EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
          child: Text(_navigationPages[index].title),
        ),
        onTap: () {
          setState(() => _selectedPageIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(_navigationPages[_selectedPageIndex].title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: _selectedPageIndex == 2 ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.movie),
              text: 'Movies',
            ),
            Tab(
              icon: Icon(Icons.video_library),
              text: 'TV Shows',
            ),
          ],
        ) : null,
        actions: [
          _selectedPageIndex <= 1 ? IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              navigate(
                destination: Search(pageType: _navigationPages[_selectedPageIndex].pageType),
              );
            },
          ) : Container(),
        ],
      ),
      body: _navigationPages[_selectedPageIndex].widget,
      drawer: SafeArea(
        top: true,
        left: true,
        right: true,
        bottom: false,
        child: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 200,
                child: Center(
                  child: Image.asset(
                  'assets/icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Divider(color: Theme.of(context).cardColor),
              ),
              for (final (index, _) in _navigationPages.indexed) NavigationTile(index),
            ],
          ),
        ),
      ),
    );
  }
}