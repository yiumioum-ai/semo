import "dart:convert";

import "package:semo/models/server.dart";
import "package:semo/models/subtitle_style.dart";
import "package:shared_preferences/shared_preferences.dart";

class Preferences {
  factory Preferences() => _instance;

  Preferences._internal();
  static final Preferences _instance = Preferences._internal();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool?> setServer(Server server) async => await _prefs?.setString("server", server.name);

  Future<bool?> setSeekDuration(int seekDuration) async => await _prefs?.setInt("seekDuration", seekDuration);

  Future<bool?> setSubtitlesStyle(SubtitleStyle subtitlesStyle) async => await _prefs?.setString("subtitleStyle", json.encode(subtitlesStyle.toJson()));

  String getServer() => _prefs?.getString("server") ?? "Random";

  int getSeekDuration() => _prefs?.getInt("seekDuration") ?? 15;

  SubtitleStyle getSubtitlesStyle() {
    Map<String, dynamic> data = json.decode(_prefs?.getString("subtitleStyle") ?? "{}");
    return SubtitleStyle.fromJson(data);
  }

  Future<bool?> clear() async => await _prefs?.clear();
}