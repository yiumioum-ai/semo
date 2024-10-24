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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              SettingsList(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                lightTheme: SettingsThemeData(settingsListBackground: Theme.of(context).scaffoldBackgroundColor),
                darkTheme: SettingsThemeData(settingsListBackground: Theme.of(context).scaffoldBackgroundColor),
                sections: [
                  SettingsSection(
                    title: Text('Account'),
                    tiles: [
                      SettingsTile(
                        title: Text('Sign out'),
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
            ],
          ),
        ),
      ),
    );
  }
}