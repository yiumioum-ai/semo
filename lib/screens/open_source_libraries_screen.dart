import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenSourceLibrariesScreen extends StatefulWidget {
  @override
  _OpenSourceLibrariesScreenState createState() => _OpenSourceLibrariesScreenState();
}

class _OpenSourceLibrariesScreenState extends State<OpenSourceLibrariesScreen> {
  List<String> _libraries = [
    'archive',
    'audio_video_progress_bar',
    'cached_network_image',
    'carousel_slider',
    'connectivity_plus',
    'firebase_analytics',
    'firebase_auth',
    'firebase_core',
    'firebase_crashlytics',
    'cloud_firestore',
    'firebase_remote_config',
    'flutter_settings_ui',
    'font_awesome_flutter',
    'google_fonts',
    'google_sign_in',
    'http',
    'infinite_scroll_pagination',
    'package_info_plus',
    'path_provider',
    'shared_preferences',
    'smooth_page_indicator',
    'subtitle_wrapper_package',
    'swipeable_page_route',
    'url_launcher',
    'wakelock_plus',
    'video_player',
  ];

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
        screenName: 'Open Source Libraries',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open Source libraries'),
      ),
      body: ListView.builder(
        itemCount: _libraries.length,
        itemBuilder: (context, index) {
          String library = _libraries[index];
          return ListTile(
            title: Text(
              library,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            onTap: () async {
              await launchUrl(Uri.parse('https://pub.dev/packages$library'));
            },
          );
        },
      ),
    );
  }
}