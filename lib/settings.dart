import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:semo/landing.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Settings',
      );
    });
  }

  SectionTitle(String title) {
    return Text(
      'Playback',
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: 20,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  SettingsTile SectionTile({
    required String title,
    String description = '',
    required IconData icon,
    Widget? trailing,
    required Function(BuildContext context) onPressed,
  }) {
    return SettingsTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium,
      ),
      description: Text(
        description,
        style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
      ),
      leading: Icon(icon),
      trailing: trailing,
      backgroundColor: Platform.isIOS ? Theme.of(context).cardColor: Colors.transparent,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    SettingsThemeData settingsThemeData = SettingsThemeData(
      titleTextColor: Theme.of(context).primaryColor,
      settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    );

    return Scaffold(
      body: SettingsList(
        lightTheme: settingsThemeData,
        darkTheme: settingsThemeData,
        sections: [
          SettingsSection(
            title: SectionTitle('Playback'),
            tiles: [
              SectionTile(
                title: 'Server',
                description: 'Select a server that works best for you',
                icon: Icons.dns_outlined,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Subtitles',
                description: 'Customize the subtitles style to fit your preference',
                icon: Icons.subtitles_outlined,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Seek duration',
                description: 'Adjust how long the seek forward/backward duration is',
                icon: Icons.update,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Autoplay next episode',
                description: 'Automatically plays the next episode',
                icon: Icons.skip_next,
                trailing: Switch(
                  value: true,
                  onChanged: (isSelected) {},
                ),
                onPressed: (context) async {},
              ),
            ],
          ),
          SettingsSection(
            title: SectionTitle('App'),
            tiles: [
              SectionTile(
                title: 'About',
                icon: Icons.info_outline_rounded,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Open source licenses',
                icon: Icons.description_outlined,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
            ],
          ),
          SettingsSection(
            title: SectionTitle('Other'),
            tiles: [
              SectionTile(
                title: 'Clear recent searches',
                description: 'Deletes all the recent search queries',
                icon: Icons.delete_outline,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Clear recently watched',
                description: 'Deletes all the progress of recently watched movies and TV shows',
                icon: Icons.delete_outline,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SectionTile(
                title: 'Sign out',
                icon: Icons.exit_to_app,
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {
                  await FirebaseAuth.instance.signOut();
                  navigate(destination: Landing(), replace: true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}