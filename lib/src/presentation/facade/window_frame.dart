import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:window_frame/src/composition/window_frame_composition_root.dart';
import 'package:window_frame/src/domain/entities/window_entities.dart';
import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';

/// The simple entry point of the plugin: initialize the window, send it
/// commands, observe its state.
///
/// It only forwards to [WindowFrameViewModel]; there is no logic here.
abstract final class WindowFrame {
  static WindowFrameViewModel get _viewModel =>
      WindowFrameCompositionRoot.windowFrameViewModel;

  /// True where the plugin has a native implementation (Windows only for now).
  static bool get isSupported => WindowFrameCompositionRoot.isPlatformSupported;

  /// True once the native title bar is really removed.
  static ValueListenable<bool> get frameActive =>
      _viewModel.isCustomFrameActive;

  static ValueListenable<bool> get isMaximized => _viewModel.isMaximized;

  /// True while the window is the active (focused) window.
  static ValueListenable<bool> get isWindowActive => _viewModel.isWindowActive;

  /// The name of the application, ready to use as a title.
  ///
  /// It is the title the native runner gave to the window: the project name
  /// from `pubspec.yaml` (for example `my_app`) unless you changed it in
  /// `windows/runner/main.cpp`. Available after `await WindowFrame.init()`;
  /// an empty string where it is unknown (other platforms, native side
  /// missing).
  ///
  /// ```dart
  /// TitleBarContent(title: WindowFrame.applicationTitle)
  /// ```
  ///
  /// You rarely need to write this yourself: a title bar with no `title` shows
  /// the application name by default.
  static String get applicationTitle => _viewModel.applicationTitle;

  /// Call once in `main()`, after `WidgetsFlutterBinding.ensureInitialized()`
  /// and before `runApp()`. Never throws: if the native side is unavailable
  /// the app keeps the standard window frame.
  static Future<void> init([
    WindowFrameOptions options = const WindowFrameOptions(),
  ]) {
    return _viewModel.initialize(options);
  }

  static Future<void> minimize() => _viewModel.minimize();

  static Future<void> maximize() => _viewModel.maximize();

  static Future<void> restore() => _viewModel.restore();

  static Future<void> toggleMaximize() => _viewModel.toggleMaximize();

  /// Asks the window to close; the request goes through
  /// `WindowFrameScope.onCloseRequested`.
  static Future<void> close() => _viewModel.requestClose();

  static Future<void> startDrag() => _viewModel.startDrag();

  /// Changes the minimum size at runtime (also enlarges a smaller restored
  /// window; a maximized window is never constrained).
  static Future<void> setMinimumSize(Size minimumSize) =>
      _viewModel.setMinimumSize(minimumSize);
}
