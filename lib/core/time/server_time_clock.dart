typedef MonotonicElapsedReader = Duration Function();

class ServerTimeClock {
  factory ServerTimeClock() {
    final stopwatch = Stopwatch()..start();
    return ServerTimeClock.withElapsedReader(() => stopwatch.elapsed);
  }

  ServerTimeClock.withElapsedReader(this._readElapsed);

  final MonotonicElapsedReader _readElapsed;

  DateTime? _serverTimeUtc;
  Duration? _anchorElapsed;
  String? _operationalTimeZone;

  bool get isSynchronized => currentUtc() != null;

  String? get operationalTimeZone =>
      isSynchronized ? _operationalTimeZone : null;

  void synchronize({
    required DateTime serverTime,
    required String operationalTimeZone,
  }) {
    _serverTimeUtc = serverTime.toUtc();
    _anchorElapsed = _readElapsed();
    _operationalTimeZone = operationalTimeZone;
  }

  DateTime? currentUtc() {
    final serverTimeUtc = _serverTimeUtc;
    final anchorElapsed = _anchorElapsed;
    if (serverTimeUtc == null || anchorElapsed == null) return null;

    final currentElapsed = _readElapsed();
    if (currentElapsed < anchorElapsed) {
      invalidate();
      return null;
    }
    return serverTimeUtc.add(currentElapsed - anchorElapsed);
  }

  void invalidate() {
    _serverTimeUtc = null;
    _anchorElapsed = null;
    _operationalTimeZone = null;
  }
}
