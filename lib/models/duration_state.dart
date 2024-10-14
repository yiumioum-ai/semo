class DurationState {
  Duration progress;
  Duration total;
  bool isBuffering;

  DurationState({
    required this.progress,
    required this.total,
    required this.isBuffering,
  });
}