import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:semo/firebase_options.dart';
import 'package:semo/splash.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  usePathUrlStrategy();
  if (kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(Semo());
    });
  } else {
    runZonedGuarded<Future<void>>(() async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      if (kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }

      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
        runApp(Semo());
      });
    },
          (error, stack) => FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      ),
    );
  }
}

class Semo extends StatelessWidget {
  const Semo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFBD0000),
        scaffoldBackgroundColor: Color(0xFF121212),
        dialogBackgroundColor: Color(0xFF212121),
        cardColor: Color(0xFF212121),
        textTheme: TextTheme(
          titleLarge: TextStyle(
              fontSize: 32,
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
        useMaterial3: true,
      ),
      home: Splash(),
    );
  }
}
