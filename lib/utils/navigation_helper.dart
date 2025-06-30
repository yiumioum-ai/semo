import 'package:flutter/material.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class NavigationHelper {
  static Future<dynamic> navigate(
      BuildContext context,
      Widget destination, {
        bool replace = false,
      }) async {
    final pageTransition = SwipeablePageRoute(
      canOnlySwipeFromEdge: true,
      builder: (BuildContext context) => destination,
    );

    if (replace) {
      return await Navigator.pushReplacement(context, pageTransition);
    } else {
      return await Navigator.push(context, pageTransition);
    }
  }
}