import "package:flutter/material.dart";

class SubtitleStyle {
  SubtitleStyle({
    required this.hasBorder,
    required this.fontSize,
    required this.color,
    required this.borderStyle
  });

  factory SubtitleStyle.fromJson(Map<String, dynamic> json) => SubtitleStyle(
      fontSize: json["fontSize"] ?? 18.0,
      color: json["color"] ?? "Black",
      hasBorder: json["hasBorder"] ?? true,
      borderStyle: SubtitleBorderStyle(
        strokeWidth: json["borderWidth"] ?? 5.0,
        style: PaintingStyle.values.byName(json["borderStyle"] ?? "stroke"),
        color: json["borderColor"] ?? "White",
      ),
    );
  
  double fontSize;
  String color;
  bool hasBorder;
  SubtitleBorderStyle borderStyle;

  static final List<double> _fontSizes = <double>[10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0];
  static final Map<String, Color> _colors = <String, Color>{
    "White": Colors.white,
    "Black": Colors.black,
    "Yellow": Colors.yellow,
    "Orange": Colors.orange,
    "Green": Colors.green,
    "Cyan": Colors.cyan,
    "Pink": Colors.pink,
    "Purple": Colors.purple,
    "Red": Colors.red,
    "Blue Grey": Colors.blueGrey,
  };
  static final List<double> _borderWidths = <double>[1.0, 2.0, 3.0, 4.0, 5.0];

  Map<String, dynamic> toJson() => <String, dynamic>{
    "fontSize": fontSize,
    "color": color,
    "hasBorder": hasBorder,
    "borderWidth": borderStyle.strokeWidth,
    "borderStyle": borderStyle.style.name,
    "borderColor": borderStyle.color,
  };
  
  static List<double> getFontSizes() => _fontSizes;
  static Map<String, Color> getColors() => _colors;
  static List<double> getBorderWidths() => _borderWidths;
}

class SubtitleBorderStyle {
  SubtitleBorderStyle({
    required this.strokeWidth,
    required this.style,
    required this.color,
  });

  double strokeWidth;
  PaintingStyle style;
  String color;
}