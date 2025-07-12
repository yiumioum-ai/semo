import "dart:async";

import "package:firebase_core/firebase_core.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:google_fonts/google_fonts.dart";
import "package:semo/firebase_options.dart";
import "package:semo/screens/splash_screen.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/utils/preferences.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();
  await initializeFirebase();
  TMDBService.init();
  runApp(const Semo());
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    await runZonedGuarded<Future<void>>(() async {
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = crashlytics.recordFlutterFatalError;
    }, (Object error, StackTrace stack) async {
      await crashlytics.recordError(error, stack, fatal: true);
    }); 
  }
}

class Semo extends StatelessWidget {
  const Semo({super.key});

  static const Color _primary = Color(0xFFAB261D);
  static const Color _background = Color(0xFF120201);
  static const Color _surface = Color(0xFF250604);
  static const Color _onPrimary = Colors.white;
  static const Color _onSurface = Colors.white54;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Semo",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primary,
      scaffoldBackgroundColor: _background,
      cardColor: _surface,
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        titleTextStyle: GoogleFonts.freckleFace(
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _onPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _onPrimary),
        centerTitle: false,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.freckleFace(
          textStyle: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _onPrimary,
          ),
        ),
        titleMedium: GoogleFonts.freckleFace(
          textStyle: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _onPrimary,
          ),
        ),
        titleSmall: GoogleFonts.freckleFace(
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _onPrimary,
          ),
        ),
        displayLarge: GoogleFonts.lexend(
          textStyle: const TextStyle(
            fontSize: 18,
            color: _onPrimary,
          ),
        ),
        displayMedium: GoogleFonts.lexend(
          textStyle: const TextStyle(
            fontSize: 15,
            color: _onPrimary,
          ),
        ),
        displaySmall: GoogleFonts.lexend(
          textStyle: const TextStyle(
            fontSize: 14,
            color: _onPrimary,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _surface,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: _primary,
        labelColor: _primary,
        dividerColor: _surface,
        unselectedLabelColor: _onSurface,
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(_surface),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surface,
      ),
    ),
    home: SplashScreen(),
  );
}