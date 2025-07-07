import "dart:async";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:flutter/material.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";
import "package:logger/logger.dart";
import "package:swipeable_page_route/swipeable_page_route.dart";

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  StreamSubscription<InternetStatus>? _connectionSubscription;
  bool _isConnectedToInternet = true;

  final Logger logger = Logger();

  /// Override this method to provide the screen name for Firebase Analytics
  String get screenName;

  /// Override this method to handle initialization logic
  /// Called after initState and connectivity check
  Future<void> initializeScreen() async {}

  /// Override this method to provide the main content of the screen
  Widget buildContent(BuildContext context);

  /// Override this method to handle dispose logic
  /// Called after dispose
  void handleDispose() {}

  /// Override this method to customize the no internet widget
  Widget buildNoInternetWidget() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.wifi_off_sharp,
            color: Colors.white54,
            size: 80,
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: Text(
              "You have lost internet connection",
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _checkConnectivity();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );

  /// Initialize connectivity checking
  Future<void> _initConnectivity() async {
    await _checkConnectivity();

    _connectionSubscription = InternetConnection().onStatusChange.listen((InternetStatus status) async {
        if (mounted) {
          switch (status) {
            case InternetStatus.connected:
              setState(() => _isConnectedToInternet = true);
            case InternetStatus.disconnected:
              setState(() => _isConnectedToInternet = false);
          }
        }
      },
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final bool isConnected = await InternetConnection().hasInternetAccess;
      if (mounted) {
        setState(() => _isConnectedToInternet = isConnected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnectedToInternet = false);
      }
    }
  }

  /// Log screen view to Firebase Analytics
  Future<void> _logScreenView() async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: widget.runtimeType.toString(),
      );
    } catch (e, s) {
      logger.e("Failed to log screen view", error: e, stackTrace: s);
    }
  }

  /// Log custom event to Firebase Analytics
  Future<void> logAnalyticsEvent(String eventName, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e, s) {
      logger.e("Failed to log analytics event", error: e, stackTrace: s);
    }
  }

  /// Navigate to a screen
  Future<void> navigate(Widget destination, {bool replace = false}) async {
    final SwipeablePageRoute<dynamic> pageTransition = SwipeablePageRoute<dynamic>(
      canOnlySwipeFromEdge: true,
      builder: (BuildContext context) => destination,
    );

    if (replace) {
      await Navigator.pushReplacement(context, pageTransition);
    } else {
      await Navigator.push(context, pageTransition);
    }
  }

  /// Get current connectivity status
  bool get isConnectedToInternet => _isConnectedToInternet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initConnectivity();

      if (_isConnectedToInternet) {
        await _logScreenView();
      }

      if (mounted) {
        await initializeScreen();
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    handleDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show no internet widget if not connected
    if (!_isConnectedToInternet) {
      return buildNoInternetWidget();
    }

    // Build the main content
    return buildContent(context);
  }
}