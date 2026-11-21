// The only class that talks to the Flutter `MethodChannel`.
//
// It sends commands to the native window and republishes what the native
// window tells us as a stream of [WindowEvent]s.

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:window_frame/src/data/constants/window_channel_contract.dart';
import 'package:window_frame/src/data/mappers/window_channel_mappers.dart';
import 'package:window_frame/src/domain/entities/window_entities.dart';

class WindowMethodChannelDataSource {
  WindowMethodChannelDataSource({
    MethodChannel? channel,
    WindowEventMapper eventMapper = const WindowEventMapper(),
  }) : _channel =
           channel ?? const MethodChannel(WindowChannelContract.channelName),
       _eventMapper = eventMapper {
    // Registered first, so no native event can arrive before a listener exists.
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final WindowEventMapper _eventMapper;
  final StreamController<WindowEvent> _eventController =
      StreamController<WindowEvent>.broadcast();

  Stream<WindowEvent> get events => _eventController.stream;

  Future<Map<String, Object?>?> initialize(Map<String, Object?> arguments) {
    return _channel.invokeMapMethod<String, Object?>(
      WindowChannelContract.initializeMethod,
      arguments,
    );
  }

  Future<void> invokeCommand(String methodName, [Object? arguments]) {
    return _channel.invokeMethod<void>(methodName, arguments);
  }

  Future<dynamic> _handleNativeCall(MethodCall nativeCall) async {
    final WindowEvent? windowEvent = _eventMapper.toWindowEvent(nativeCall);
    if (windowEvent != null) {
      _eventController.add(windowEvent);
    }
  }
}
