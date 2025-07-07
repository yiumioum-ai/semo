import "package:flutter/material.dart";
import "package:swipeable_page_route/swipeable_page_route.dart";

class NavigationHelper {
  static Future<dynamic> navigate(BuildContext context, Widget destination, {bool replace = false}) {
    final SwipeablePageRoute<dynamic> pageTransition = SwipeablePageRoute<dynamic>(
      canOnlySwipeFromEdge: true,
      builder: (BuildContext context) => destination,
    );

    if (replace) {
      return Navigator.pushReplacement(context, pageTransition);
    } else {
      return Navigator.push(context, pageTransition);
    }
  }
}