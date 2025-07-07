enum MediaType {
  none,
  movies,
  tvShows;

  @override
  String toString() {
    switch (this) {
      case MediaType.none:
        return "None";
      case MediaType.movies:
        return "Movies";
      case MediaType.tvShows:
        return "TV Shows";
    }
  }
}