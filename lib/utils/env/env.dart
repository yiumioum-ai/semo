import "package:envied/envied.dart";

part "env.g.dart";

@Envied(path: ".env")
abstract class Env {
  @EnviedField(varName: "TMDB_ACCESS_TOKEN", obfuscate: true)
  static String tmdbAccessToken = _Env.tmdbAccessToken;

  @EnviedField(varName: "SUBDL_API_KEY", obfuscate: true)
  static String subdlApiKey = _Env.subdlApiKey;
}