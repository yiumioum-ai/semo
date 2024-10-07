import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

//ignore: must_be_immutable
class WebPlayer extends StatefulWidget {
  int id;
  String title, streamUrl;

  WebPlayer({
    required this.id,
    required this.title,
    required this.streamUrl,
  });

  @override
  _WebPlayerState createState() => _WebPlayerState();
}

class _WebPlayerState extends State<WebPlayer> {
  int? _id;
  String? _title, _streamUrl;
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: false,
    supportZoom: false,
  );
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _showControls = true;

  addToRecentlyWatched() async {
    final user = _firestore.collection('users').doc(_auth.currentUser!.uid);
    await user.get().then((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> recentlyWatched = (data['recently_watched_movies'] as List<dynamic>).cast<Map<String, dynamic>>();
        bool isInRecentlyWatched = recentlyWatched.any((movie) => movie['id'] == _id);

        if (recentlyWatched.isNotEmpty && isInRecentlyWatched) {
          for (Map<String, dynamic> movie in recentlyWatched) {
            if (movie['id'] == _id) {
              movie['timestamp'] = DateTime.now().millisecondsSinceEpoch;
              break;
            }
          }
        } else {
          recentlyWatched.add({
            'id': _id,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }

        user.set({
          'recently_watched_movies': recentlyWatched,
        }, SetOptions(merge: true));
      }, onError: (e) => print("Error getting user: $e"),
    );
  }

  forceLandscape() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  forcePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void initState() {
    _id = widget.id;
    _title = widget.title;
    _streamUrl = widget.streamUrl;
    super.initState();
    forceLandscape();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: 'Web Player',
      );
      addToRecentlyWatched();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    forcePortrait();
  }

  Widget Controls() {
    return _showControls ? AnimatedOpacity(
      opacity: _showControls ? 1 : 0,
      duration: Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.5),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  leading: BackButton(color: Colors.white),
                  title: Text(
                    _title!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _showControls = true;
                        });
                        _webViewController!.reload();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    ) : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: GestureDetector(
          child: Stack(
            children: [
              InAppWebView(
                key: _webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(_streamUrl!)),
                initialSettings: _webViewSettings,
                onWebViewCreated: (controller) => _webViewController = controller,
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) async => setState(() {
                  _isLoading = false;
                  _showControls = false;
                }),
                onConsoleMessage: (controller, consoleMessage) {},
              ),
              Controls(),
            ],
          ),
          onDoubleTap: () {
            if (_showControls) {
              setState(() => _showControls = false);
            } else {
              setState(() => _showControls = true);
              Future.delayed(Duration(seconds: 5), () {
                if (mounted) setState(() => _showControls = false);
              });
            }
          },
        ),
      ),
    );
  }
}