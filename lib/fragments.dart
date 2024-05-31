import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/favorites.dart';
import 'package:semo/landing.dart';
import 'package:semo/models/navigation_page.dart';
import 'package:semo/movies.dart';
import 'package:semo/player.dart';
import 'package:semo/search.dart';
import 'package:semo/settings.dart';
import 'package:semo/tv_shows.dart';
import 'package:semo/utils/enums.dart';

class Fragments extends StatefulWidget {
  @override
  _FragmentsState createState() => _FragmentsState();
}

class _FragmentsState extends State<Fragments> {
  int _selectedPageIndex = 0;
  List<NavigationPage> _navigationPages = [];

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
          widget: Favorites(),
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

  _onNavigationTileTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
    Navigator.pop(context);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selected: _selectedPageIndex == index,
        leading: Icon(_navigationPages[index].icon),
        title: Text(_navigationPages[index].title),
        onTap: () {
          _onNavigationTileTapped(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
            _navigationPages[_selectedPageIndex].title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          _selectedPageIndex != 3 ? IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              /*navigate(
                destination: Search(
                  pageType: _navigationPages[_selectedPageIndex].pageType,
                ),
              );*/
              navigate(
                destination: Player(),
              );
            },
          ) : Container(),
        ],
      ),
      body: _navigationPages[_selectedPageIndex].widget,
      drawer: SafeArea(
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