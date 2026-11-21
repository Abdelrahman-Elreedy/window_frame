// One small class per thing the app can ask of the window. Each use case only
// forwards to the [WindowPlatformRepository] contract; the data layer decides
// how the request reaches the native window.

import 'dart:ui' show Size;

import 'package:window_frame/src/domain/entities/window_entities.dart';
import 'package:window_frame/src/domain/repositories/window_platform_repository.dart';

/// Applies the startup options to the native window.
class InitializeWindowFrameUseCase {
  const InitializeWindowFrameUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<WindowInitializationResult> call(WindowFrameOptions options) =>
      _repository.initialize(options);
}

/// Minimizes the window to the taskbar.
class MinimizeWindowUseCase {
  const MinimizeWindowUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.minimize();
}

/// Maximizes the window.
class MaximizeWindowUseCase {
  const MaximizeWindowUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.maximize();
}

/// Brings a maximized or minimized window back to its normal size.
class RestoreWindowUseCase {
  const RestoreWindowUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.restore();
}

/// Maximizes a normal window, or restores a maximized one.
class ToggleMaximizeWindowUseCase {
  const ToggleMaximizeWindowUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.toggleMaximize();
}

/// Asks the window to close. The request goes through the app's close handler
/// (`WindowFrameScope.onCloseRequested`) before the window really closes.
class RequestWindowCloseUseCase {
  const RequestWindowCloseUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.requestClose();
}

/// Starts moving the window with the mouse (used by the title bar drag area).
class StartWindowDragUseCase {
  const StartWindowDragUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call() => _repository.startDrag();
}

/// Changes the minimum window size at runtime.
class SetMinimumWindowSizeUseCase {
  const SetMinimumWindowSizeUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Future<void> call(Size minimumSize) =>
      _repository.setMinimumSize(minimumSize);
}

/// Streams what happens to the native window (maximize, activation...).
class ObserveWindowEventsUseCase {
  const ObserveWindowEventsUseCase(this._repository);

  final WindowPlatformRepository _repository;

  Stream<WindowEvent> call() => _repository.events;
}
