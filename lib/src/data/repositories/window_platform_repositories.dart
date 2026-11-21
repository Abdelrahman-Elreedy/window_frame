// The two implementations of [WindowPlatformRepository]: the Windows one (talks
// to the native plugin) and the no-op one (every other platform), plus the
// retry policy the Windows one uses at start-up.

import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;

import 'package:window_frame/src/data/constants/window_channel_contract.dart';
import 'package:window_frame/src/data/datasources/window_method_channel_data_source.dart';
import 'package:window_frame/src/data/mappers/window_channel_mappers.dart';
import 'package:window_frame/src/domain/entities/window_entities.dart';
import 'package:window_frame/src/domain/repositories/window_platform_repository.dart';

/// Windows implementation of [WindowPlatformRepository]: every call goes to
/// the native plugin through [WindowMethodChannelDataSource].
///
/// No method ever throws: a failing native call is logged and the app keeps
/// working with the standard window frame.
class WindowPlatformRepositoryImpl implements WindowPlatformRepository {
  WindowPlatformRepositoryImpl({
    required WindowMethodChannelDataSource dataSource,
    WindowFrameOptionsMapper optionsMapper = const WindowFrameOptionsMapper(),
    WindowInitializationResultMapper resultMapper =
        const WindowInitializationResultMapper(),
    NativeInitializationRetryPolicy retryPolicy =
        const NativeInitializationRetryPolicy(),
  }) : _dataSource = dataSource,
       _optionsMapper = optionsMapper,
       _resultMapper = resultMapper,
       _retryPolicy = retryPolicy;

  final WindowMethodChannelDataSource _dataSource;
  final WindowFrameOptionsMapper _optionsMapper;
  final WindowInitializationResultMapper _resultMapper;
  final NativeInitializationRetryPolicy _retryPolicy;

  @override
  Stream<WindowEvent> get events => _dataSource.events;

  @override
  Future<WindowInitializationResult> initialize(
    WindowFrameOptions options,
  ) async {
    final Map<String, Object?> nativeArguments = _optionsMapper
        .toNativeArguments(options);

    for (int attempt = 1; attempt <= _retryPolicy.maximumAttempts; attempt++) {
      try {
        final Map<String, Object?>? nativeResult = await _dataSource
            .initialize(nativeArguments)
            .timeout(_retryPolicy.callTimeout);
        return _resultMapper.toInitializationResult(nativeResult);
      } on MissingPluginException {
        // The native side is not registered yet: try again below.
      } on PlatformException catch (error) {
        if (error.code != WindowChannelContract.windowNotReadyErrorCode) {
          return _unavailableBecause('$error');
        }
        // The window is not ready yet: try again below.
      } on TimeoutException {
        return _unavailableBecause('the native call timed out');
      } catch (error) {
        return _unavailableBecause('$error');
      }
      await Future<void>.delayed(_retryPolicy.delayBetweenAttempts);
    }
    return _unavailableBecause('the native side never became available');
  }

  @override
  Future<void> minimize() => _runCommand(WindowChannelContract.minimizeMethod);

  @override
  Future<void> maximize() => _runCommand(WindowChannelContract.maximizeMethod);

  @override
  Future<void> restore() => _runCommand(WindowChannelContract.restoreMethod);

  @override
  Future<void> toggleMaximize() =>
      _runCommand(WindowChannelContract.toggleMaximizeMethod);

  @override
  Future<void> requestClose() =>
      _runCommand(WindowChannelContract.requestCloseMethod);

  @override
  Future<void> startDrag() =>
      _runCommand(WindowChannelContract.startDragMethod);

  @override
  Future<void> setMinimumSize(Size minimumSize) {
    return _runCommand(
      WindowChannelContract.setMinimumSizeMethod,
      <String, Object?>{
        WindowChannelContract.minimumWidthKey: minimumSize.width,
        WindowChannelContract.minimumHeightKey: minimumSize.height,
      },
    );
  }

  Future<void> _runCommand(String methodName, [Object? arguments]) async {
    try {
      await _dataSource.invokeCommand(methodName, arguments);
    } catch (error) {
      debugPrint('window_frame: "$methodName" failed: $error');
    }
  }

  WindowInitializationResult _unavailableBecause(String reason) {
    debugPrint(
      'window_frame: initialization failed ($reason), '
      'keeping the standard window frame.',
    );
    return const WindowInitializationResult.unavailable();
  }
}

/// Used on platforms without a native implementation (everything except
/// Windows): every command does nothing and no event is ever published.
class UnsupportedWindowPlatformRepository implements WindowPlatformRepository {
  const UnsupportedWindowPlatformRepository();

  @override
  Stream<WindowEvent> get events => const Stream<WindowEvent>.empty();

  @override
  Future<WindowInitializationResult> initialize(
    WindowFrameOptions options,
  ) async {
    return const WindowInitializationResult.unavailable();
  }

  @override
  Future<void> minimize() async {}

  @override
  Future<void> maximize() async {}

  @override
  Future<void> restore() async {}

  @override
  Future<void> toggleMaximize() async {}

  @override
  Future<void> requestClose() async {}

  @override
  Future<void> startDrag() async {}

  @override
  Future<void> setMinimumSize(Size minimumSize) async {}
}

/// How patiently the app waits for the native side to answer "initialize".
///
/// The native plugin may not be registered the very first instant `main()`
/// runs, so a few quick retries make start-up reliable.
class NativeInitializationRetryPolicy {
  const NativeInitializationRetryPolicy({
    this.maximumAttempts = 3,
    this.delayBetweenAttempts = const Duration(milliseconds: 100),
    this.callTimeout = const Duration(seconds: 2),
  });

  final int maximumAttempts;
  final Duration delayBetweenAttempts;

  /// A single native call that takes longer than this counts as a failure.
  final Duration callTimeout;
}
