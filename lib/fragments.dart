import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/favorite_movies.dart';
import 'package:semo/favorite_tv_shows.dart';
import 'package:semo/landing.dart';
import 'package:semo/models/navigation_page.dart';
import 'package:semo/movies.dart';
import 'package:semo/search.dart';
import 'package:semo/settings.dart';
import 'package:semo/tv_shows.dart';
import 'package:semo/utils/enums.dart';

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
          widget: TVShows(),
          pageType: PageType.tv_shows,
        ),
        NavigationPage(
          icon: Icons.favorite,
          title: 'Favorites',
          widget: TabBarView(
            controller: _tabController,
            children: [
              FavoriteMovies(),
              FavoriteTvShows(),
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

  @override
  void initState() {
    super.initState();
    checkUserSession();
    populatePages();
  }

  Widget NavigationTile(int index) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: ListTile(
        textColor: Colors.white,
        iconColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(.3),
        titleTextStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
          fontWeight: _selectedPageIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: _selectedPageIndex == index,
        leading: Icon(_navigationPages[index].icon),
        title: Text(_navigationPages[index].title),
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
                height: 150,
                child: Center(
                  child: Image.asset(
                  'assets/icon.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
              for (final (index, item) in _navigationPages.indexed) NavigationTile(index),
            ],
          ),
        ),
      ),
    );
  }
}