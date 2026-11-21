import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;

/// Counts a double-click by hand from two single clicks.
///
/// A real double-tap recognizer holds the gesture arena and delays every tap in
/// the title bar, so the bar counts the clicks itself: two clicks within
/// [kDoubleTapTimeout] (and, when [maxDistance] is given, close to each other)
/// make a double-click. It knows no widget; the views feed it positions.
class DoubleClickDetector {
  DoubleClickDetector({this.maxDistance, Duration Function()? clock})
    : _clock = clock ?? _stopwatchClock();

  /// How far apart (logical px) two clicks may be. `null`: any distance.
  final double? maxDistance;

  final Duration Function() _clock;
  Duration? _time;
  Offset? _position;

  static Duration Function() _stopwatchClock() {
    final Stopwatch stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  /// Whether a click at [position] would be the second click of a double-click
  /// (a click was remembered soon enough, and close enough).
  bool isDoubleClickAt(Offset position) {
    final Duration? time = _time;
    final Offset? previous = _position;
    if (time == null || previous == null) return false;
    if (_clock() - time > kDoubleTapTimeout) return false;
    final double? limit = maxDistance;
    return limit == null || (position - previous).distance <= limit;
  }

  /// Remembers a click at [position] as the possible first click.
  void note(Offset position) {
    _time = _clock();
    _position = position;
  }

  /// Registers a click. Returns `true` when it completes a double-click (the
  /// memory is cleared); otherwise it is remembered as a first click.
  bool register(Offset position) {
    if (isDoubleClickAt(position)) {
      forget();
      return true;
    }
    note(position);
    return false;
  }

  /// Forgets the remembered click.
  void forget() {
    _time = null;
    _position = null;
  }
}
