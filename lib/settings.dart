import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:page_transition/page_transition.dart';
import 'package:semo/landing.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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

  @override
  Widget build(BuildContext context) {
    SettingsThemeData settingsThemeData = SettingsThemeData(
      titleTextColor: Theme.of(context).primaryColor,
      settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SettingsList(
        lightTheme: settingsThemeData,
        darkTheme: settingsThemeData,
        sections: [
          SettingsSection(
            title: Text(
              'Playback',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            tiles: [
              SettingsTile(
                title: Text(
                  'Server',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Select a server that works best for you',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.dns_outlined),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Subtitles',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Customize the subtitles style to fit your preference',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.subtitles_outlined),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Seek duration',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Adjust how long the seek forward/backward duration is',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.update),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Autoplay next episode',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Automatically plays the next episode',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.skip_next),
                trailing: Switch(value: true, onChanged: (isSelected) {}),
                onPressed: (context) async {},
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'App',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            tiles: [
              SettingsTile(
                title: Text(
                  'About',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                leading: Icon(Icons.info_outline_rounded),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Open source licenses',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                leading: Icon(Icons.description_outlined),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'Other',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            tiles: [
              SettingsTile(
                title: Text(
                  'Clear recent searches',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Deletes all the recent search queries',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.delete_outline),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Clear recently watched',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                description: Text(
                  'Deletes all the recently watched movies and TV shows',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.white54),
                ),
                leading: Icon(Icons.delete_outline),
                trailing: Platform.isIOS ? Icon(Icons.keyboard_arrow_right_outlined) : null,
                onPressed: (context) async {},
              ),
              SettingsTile(
                title: Text(
                  'Sign out',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                leading: Icon(Icons.exit_to_app),
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