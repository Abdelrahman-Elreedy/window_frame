// Everything the application needs from the native window.
//
// The domain layer depends only on this contract. The data layer implements
// it (method channel on Windows, a no-op on other platforms).

import 'dart:ui' show Size;

import 'package:window_frame/src/domain/entities/window_entities.dart';

abstract interface class WindowPlatformRepository {
  /// Events pushed by the native window (maximize, activation...).
  Stream<WindowEvent> get events;

  /// Applies [options] and reports the resulting window state. Never throws.
  Future<WindowInitializationResult> initialize(WindowFrameOptions options);

  Future<void> minimize();
  Future<void> maximize();
  Future<void> restore();
  Future<void> toggleMaximize();

  /// Asks the window to close (the close request can still be intercepted).
  Future<void> requestClose();

  /// Starts moving the window with the mouse.
  Future<void> startDrag();

  Future<void> setMinimumSize(Size minimumSize);
}
