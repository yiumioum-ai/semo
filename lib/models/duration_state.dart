class DurationState {
  Duration progress;
  Duration total;
  bool isBuffering;

  DurationState({
    this.progress = Duration.zero,
    this.total = Duration.zero,
    this.isBuffering = true,
  });
}