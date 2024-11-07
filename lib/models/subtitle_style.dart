import 'package:flutter/material.dart';

class SubtitleStyle {
  bool hasBorder;
  double fontSize;
  Color color;
  SubtitleBorderStyle borderStyle;
  SubtitlePosition position;

  SubtitleStyle({
    required this.hasBorder,
    required this.fontSize,
    required this.color,
    required this.borderStyle,
    required this.position,
  });

  factory SubtitleStyle.fromJson(Map<String, dynamic> json) {
    return SubtitleStyle(
      hasBorder: json['hasBorder'] ?? false,
      fontSize: json['fontSize'] ?? 18.0,
      color: json['color'] != null ? Color(json['color']) : Colors.black,
      borderStyle: SubtitleBorderStyle(
        strokeWidth: json['borderWidth'] ?? 2.0,
        style: PaintingStyle.values.byName(json['borderStyle'] ?? 'stroke'),
        color: json['borderColor'] != null ? Color(json['borderColor']) : Colors.black,
      ),
      position: SubtitlePosition(
        left: json['positionLeft'] ?? 0.0,
        right: json['positionRight'] ?? 0.0,
        bottom: json['positionBottom'] ?? 50.0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasBorder': hasBorder,
      'fontSize': fontSize,
      'color': color.value,
      'borderWidth': borderStyle.strokeWidth,
      'borderStyle': borderStyle.style.name,
      'borderColor': borderStyle.color.value,
      'positionLeft': position.left,
      'positionRight': position.right,
      'positionBottom': position.bottom,
    };
  }
}

class SubtitleBorderStyle {
  final double strokeWidth;
  final PaintingStyle style;
  final Color color;

  const SubtitleBorderStyle({
    required this.strokeWidth,
    required this.style,
    required this.color,
  });
}

class SubtitlePosition {
  final double left;
  final double right;
  final double bottom;

  const SubtitlePosition({
    required this.left,
    required this.right,
    required this.bottom,
  });
}