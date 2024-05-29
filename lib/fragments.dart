import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/favorites.dart';
import 'package:semo/home.dart';
import 'package:semo/landing.dart';
import 'package:semo/models/navigation_page.dart';
import 'package:semo/movies.dart';
import 'package:semo/settings.dart';
import 'package:semo/tv_shows.dart';

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
        );
      }
    });
  }

  populatePages() {
    setState(() {
      _navigationPages = [
        NavigationPage(
          icon: Icons.home,
          title: 'Home',
          widget: Home(),
        ),
        NavigationPage(
          icon: Icons.movie,
          title: 'Movies',
          widget: Movies(),
        ),
        NavigationPage(
          icon: Icons.video_library,
          title: 'TV Shows',
          widget: TVShows(),
        ),
        NavigationPage(
          icon: Icons.favorite,
          title: 'Favorites',
          widget: Favorites(),
        ),
        NavigationPage(
          icon: Icons.settings,
          title: 'Settings',
          widget: Settings(),
        ),
      ];
    });
  }

  navigate({required Widget destination}) async {
    await Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: destination,
      ),
    );
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
        title: Text(
            _navigationPages[_selectedPageIndex].title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              NavigationTile(0),
              NavigationTile(1),
              NavigationTile(2),
              NavigationTile(3),
              NavigationTile(4),
            ],
          ),
        ),
      ),
    );
  }
}