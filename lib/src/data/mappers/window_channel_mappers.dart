// Translate between the domain objects and what travels on the method
// channel (in both directions).

import 'package:flutter/services.dart' show MethodCall;

import 'package:window_frame/src/data/constants/window_channel_contract.dart';
import 'package:window_frame/src/domain/entities/window_entities.dart';

/// Turns a call coming from the native side into a [WindowEvent].
class WindowEventMapper {
  const WindowEventMapper();

  /// Returns `null` for calls this version does not know.
  WindowEvent? toWindowEvent(MethodCall nativeCall) {
    final Object? argument = nativeCall.arguments;
    if (argument is! bool) return null;

    switch (nativeCall.method) {
      case WindowChannelContract.maximizedStateChangedEvent:
        return MaximizedStateChangedEvent(isMaximized: argument);
      case WindowChannelContract.activationStateChangedEvent:
        return ActivationStateChangedEvent(isActive: argument);
      default:
        return null;
    }
  }
}

/// Turns [WindowFrameOptions] into the arguments the native side expects.
class WindowFrameOptionsMapper {
  const WindowFrameOptionsMapper();

  Map<String, Object?> toNativeArguments(WindowFrameOptions options) {
    return <String, Object?>{
      WindowChannelContract.minimumWidthKey: options.minimumSize.width,
      WindowChannelContract.minimumHeightKey: options.minimumSize.height,
      WindowChannelContract.startMaximizedKey: options.startMaximized,
      WindowChannelContract.customFrameKey: options.customFrame,
      WindowChannelContract.frameBorderWidthKey: options.frameBorderWidth,
    };
  }
}

/// Turns the native "initialize" answer into a [WindowInitializationResult].
class WindowInitializationResultMapper {
  const WindowInitializationResultMapper();

  WindowInitializationResult toInitializationResult(
    Map<String, Object?>? nativeResult,
  ) {
    if (nativeResult == null) {
      return const WindowInitializationResult.unavailable();
    }
    return WindowInitializationResult(
      isCustomFrameActive: _readBoolean(
        nativeResult,
        WindowChannelContract.customFrameActiveKey,
        fallback: false,
      ),
      isMaximized: _readBoolean(
        nativeResult,
        WindowChannelContract.isMaximizedKey,
        fallback: false,
      ),
      isWindowActive: _readBoolean(
        nativeResult,
        WindowChannelContract.isWindowActiveKey,
        fallback: true,
      ),
      applicationTitle: _readString(
        nativeResult,
        WindowChannelContract.applicationTitleKey,
      ),
    );
  }

  String _readString(Map<String, Object?> source, String key) {
    final Object? value = source[key];
    return value is String ? value : '';
  }

  bool _readBoolean(
    Map<String, Object?> source,
    String key, {
    required bool fallback,
  }) {
    final Object? value = source[key];
    return value is bool ? value : fallback;
  }
}
