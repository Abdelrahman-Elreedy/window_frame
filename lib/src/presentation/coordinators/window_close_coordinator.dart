import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';

/// Called when the user asks to close the window (caption close button,
/// Alt+F4, taskbar...). Return `true` to close, `false` to keep the window.
///
/// [context] is inside the window's Navigator, so `showDialog` works and the
/// dialog is centered on the window.
typedef WindowCloseRequestHandler = Future<bool> Function(BuildContext context);

/// Runs the app's close handler when Flutter reports an exit request.
///
/// Flutter's Windows embedder sends every close of the last window through
/// `AppLifecycleListener.onExitRequested`, so one hook covers all the ways of
/// closing the window.
class WindowCloseCoordinator {
  WindowCloseCoordinator({
    required WindowCloseRequestHandler? Function() requestHandlerProvider,
    required BuildContext? Function() contextProvider,
  }) : _requestHandlerProvider = requestHandlerProvider,
       _contextProvider = contextProvider;

  final WindowCloseRequestHandler? Function() _requestHandlerProvider;
  final BuildContext? Function() _contextProvider;

  bool _isHandlingRequest = false;

  Future<AppExitResponse> handleExitRequest() async {
    final WindowCloseRequestHandler? requestHandler = _requestHandlerProvider();
    final BuildContext? context = _contextProvider();
    if (requestHandler == null || context == null || !context.mounted) {
      return AppExitResponse.exit;
    }
    if (_isHandlingRequest) {
      // A confirmation is already on screen: ignore the repeated request.
      return AppExitResponse.cancel;
    }

    _isHandlingRequest = true;
    try {
      final bool isCloseAllowed = await requestHandler(context);
      return isCloseAllowed ? AppExitResponse.exit : AppExitResponse.cancel;
    } catch (error) {
      // Never trap the user in a window that cannot be closed.
      debugPrint('window_frame: onCloseRequested failed: $error');
      return AppExitResponse.exit;
    } finally {
      _isHandlingRequest = false;
    }
  }
}
