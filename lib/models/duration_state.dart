class DurationState {
  Duration progress;
  Duration buffered;
  Duration total;

  DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });
}