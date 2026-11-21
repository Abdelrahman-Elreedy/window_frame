import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import 'package:window_frame/src/domain/entities/window_entities.dart';
import 'package:window_frame/src/domain/use_cases/window_use_cases.dart';

/// State and commands of the native window, for the views.
///
/// Widgets listen to [isCustomFrameActive], [isMaximized] and [isWindowActive]
/// and call the commands. This class knows no widget and no channel: it only
/// talks to use cases.
class WindowFrameViewModel {
  WindowFrameViewModel({
    required InitializeWindowFrameUseCase initializeWindowFrame,
    required MinimizeWindowUseCase minimizeWindow,
    required MaximizeWindowUseCase maximizeWindow,
    required RestoreWindowUseCase restoreWindow,
    required ToggleMaximizeWindowUseCase toggleMaximizeWindow,
    required RequestWindowCloseUseCase requestWindowClose,
    required StartWindowDragUseCase startWindowDrag,
    required SetMinimumWindowSizeUseCase setMinimumWindowSize,
    required ObserveWindowEventsUseCase observeWindowEvents,
  }) : _initializeWindowFrame = initializeWindowFrame,
       _minimizeWindow = minimizeWindow,
       _maximizeWindow = maximizeWindow,
       _restoreWindow = restoreWindow,
       _toggleMaximizeWindow = toggleMaximizeWindow,
       _requestWindowClose = requestWindowClose,
       _startWindowDrag = startWindowDrag,
       _setMinimumWindowSize = setMinimumWindowSize {
    _eventSubscription = observeWindowEvents().listen(_applyWindowEvent);
  }

  final InitializeWindowFrameUseCase _initializeWindowFrame;
  final MinimizeWindowUseCase _minimizeWindow;
  final MaximizeWindowUseCase _maximizeWindow;
  final RestoreWindowUseCase _restoreWindow;
  final ToggleMaximizeWindowUseCase _toggleMaximizeWindow;
  final RequestWindowCloseUseCase _requestWindowClose;
  final StartWindowDragUseCase _startWindowDrag;
  final SetMinimumWindowSizeUseCase _setMinimumWindowSize;

  late final StreamSubscription<WindowEvent> _eventSubscription;

  final ValueNotifier<bool> _isCustomFrameActive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isMaximized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isWindowActive = ValueNotifier<bool>(true);

  /// True once the native title bar is really removed.
  ValueListenable<bool> get isCustomFrameActive => _isCustomFrameActive;

  ValueListenable<bool> get isMaximized => _isMaximized;

  /// True while the window is the active (focused) window.
  ValueListenable<bool> get isWindowActive => _isWindowActive;

  String _applicationTitle = '';

  /// The application name: the title the native runner gave to the window,
  /// which is the project name from `pubspec.yaml` unless `main.cpp` was
  /// edited. Empty until [initialize] finishes (or when it is unknown).
  String get applicationTitle => _applicationTitle;

  Future<void> initialize(WindowFrameOptions options) async {
    final result = await _initializeWindowFrame(options);
    _isCustomFrameActive.value = result.isCustomFrameActive;
    _isMaximized.value = result.isMaximized;
    _isWindowActive.value = result.isWindowActive;
    _applicationTitle = result.applicationTitle;
  }

  Future<void> minimize() => _minimizeWindow();

  Future<void> maximize() => _maximizeWindow();

  Future<void> restore() => _restoreWindow();

  Future<void> toggleMaximize() => _toggleMaximizeWindow();

  Future<void> requestClose() => _requestWindowClose();

  Future<void> startDrag() => _startWindowDrag();

  Future<void> setMinimumSize(Size minimumSize) =>
      _setMinimumWindowSize(minimumSize);

  void dispose() {
    _eventSubscription.cancel();
    _isCustomFrameActive.dispose();
    _isMaximized.dispose();
    _isWindowActive.dispose();
  }

  void _applyWindowEvent(WindowEvent event) {
    switch (event) {
      case MaximizedStateChangedEvent(:final bool isMaximized):
        _isMaximized.value = isMaximized;
      case ActivationStateChangedEvent(:final bool isActive):
        _isWindowActive.value = isActive;
    }
  }
}
