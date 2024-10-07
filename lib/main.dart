import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:semo/firebase_options.dart';
import 'package:semo/splash.dart';

void main() async {
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};

  if (kIsWeb) usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(Semo());
  });
}

initializeFirebase() async {
  FirebaseApp app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instanceFor(app: app);

  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  await remoteConfig.setDefaults({
    'appVersion': packageInfo.version,
  });

  await remoteConfig.fetchAndActivate();

  if (!kIsWeb) remoteConfig.onConfigUpdated.listen((event) async => await remoteConfig.activate());

  FirebaseCrashlytics crashlytics = await FirebaseCrashlytics.instance;
  runZonedGuarded<Future<void>>(() async {
    if (!kIsWeb) {
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = crashlytics.recordFlutterFatalError;
    }
  }, (error, stack) async {
    if (!kIsWeb) await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class Semo extends StatelessWidget {
  const Semo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
        primaryColor: Color(0xFFAB261D),
        scaffoldBackgroundColor: Color(0xFF121212),
        dialogBackgroundColor: Color(0xFF212121),
        cardColor: Color(0xFF212121),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
          ),
          displayMedium: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          displaySmall: TextStyle(
              fontSize: 12,
              color: Colors.white,
          ),
        ),
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF121212),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: Splash(),
    );
  }
}
