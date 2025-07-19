import "package:semo/enums/media_type.dart";

abstract class AppEvent {
  const AppEvent();
}

class LoadFavorites extends AppEvent {}

class AddFavorite extends AppEvent {
  const AddFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class RemoveFavorite extends AppEvent {
  const RemoveFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class ClearError extends AppEvent {}