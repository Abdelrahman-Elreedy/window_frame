// The plain data of the window domain: events, startup options and the
// result of the native initialization. Nothing here knows channels or widgets.

import 'dart:ui' show Size;

/// Something that happened to the native window and that the app may react to.
sealed class WindowEvent {
  const WindowEvent();
}

/// The window was maximized or restored.
final class MaximizedStateChangedEvent extends WindowEvent {
  const MaximizedStateChangedEvent({required this.isMaximized});

  final bool isMaximized;
}

/// The window gained or lost the keyboard focus (became the active window).
final class ActivationStateChangedEvent extends WindowEvent {
  const ActivationStateChangedEvent({required this.isActive});

  final bool isActive;
}

/// Startup configuration of the native window, passed once to
/// `WindowFrame.init`.
///
/// This is a plain value object: it knows nothing about channels or widgets.
class WindowFrameOptions {
  const WindowFrameOptions({
    this.minimumSize = const Size(800, 600),
    this.startMaximized = false,
    this.customFrame = true,
    this.frameBorderWidth = 0,
  }) : assert(frameBorderWidth >= 0);

  /// The window cannot be resized below this size (logical pixels).
  /// Use [Size.zero] to disable the limit.
  final Size minimumSize;

  /// Open the window maximized. Honored only if `WindowFrame.init` runs before
  /// the first frame is shown, i.e. before `runApp()`.
  final bool startMaximized;

  /// Remove the native title bar. With `false` the standard Windows frame is
  /// kept and `WindowFrameScope` draws nothing.
  final bool customFrame;

  /// How many pixels of the native Windows frame (its thin border and shadow
  /// edge) are extended into the app area on every side.
  ///
  /// `0` (the default) extends nothing: the cleanest look. A value above 0 is
  /// yours to try; on the machine where this was tested, `1` made the window
  /// border look thicker. The native side keeps it between 0 and 16. Applies only
  /// when [customFrame] is true.
  final int frameBorderWidth;
}

/// What the native side reports right after the window frame is initialized.
class WindowInitializationResult {
  const WindowInitializationResult({
    required this.isCustomFrameActive,
    required this.isMaximized,
    required this.isWindowActive,
    this.applicationTitle = '',
  });

  /// Used when the native side is missing or failed: the app simply keeps the
  /// standard window frame.
  const WindowInitializationResult.unavailable()
    : isCustomFrameActive = false,
      isMaximized = false,
      isWindowActive = true,
      applicationTitle = '';

  /// True once the native title bar is really removed.
  final bool isCustomFrameActive;
  final bool isMaximized;
  final bool isWindowActive;

  /// The title the native runner gave to the window. By default Flutter uses
  /// the project name from `pubspec.yaml`. Empty when it is unknown.
  final String applicationTitle;
}
