import 'package:flutter/material.dart';

class SubtitleStyle {
  static List<double> fontSizes = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0];
  static Map<String, Color> colors = {
    'White': Colors.white,
    'Black': Colors.black,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Green': Colors.green,
    'Cyan': Colors.cyan,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Red': Colors.red,
    'Blue Grey': Colors.blueGrey,
  };
  static List<double> borderWidths = [1.0, 2.0, 3.0, 4.0, 5.0];

  double fontSize;
  String color;
  bool hasBorder;
  SubtitleBorderStyle borderStyle;

  SubtitleStyle({
    required this.hasBorder,
    required this.fontSize,
    required this.color,
    required this.borderStyle
  });

  factory SubtitleStyle.fromJson(Map<String, dynamic> json) {
    return SubtitleStyle(
      fontSize: json['fontSize'] ?? 18.0,
      color: json['color'] != null ? json['color'] : 'Black',
      hasBorder: json['hasBorder'] ?? true,
      borderStyle: SubtitleBorderStyle(
        strokeWidth: json['borderWidth'] ?? 5.0,
        style: PaintingStyle.values.byName(json['borderStyle'] ?? 'stroke'),
        color: json['borderColor'] != null ? json['borderColor'] : 'White',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'color': color,
      'hasBorder': hasBorder,
      'borderWidth': borderStyle.strokeWidth,
      'borderStyle': borderStyle.style.name,
      'borderColor': borderStyle.color,
    };
  }
}

class SubtitleBorderStyle {
  double strokeWidth;
  PaintingStyle style;
  String color;

  SubtitleBorderStyle({
    required this.strokeWidth,
    required this.style,
    required this.color,
  });
}