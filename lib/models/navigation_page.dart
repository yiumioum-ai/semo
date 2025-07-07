import 'package:flutter/material.dart';
import 'package:semo/enums/media_type.dart';

class NavigationPage {
  IconData icon;
  String title;
  Widget widget;
  MediaType mediaType;

  NavigationPage({
    required this.icon,
    required this.title,
    required this.widget,
    this.mediaType = MediaType.none,
  });
}
