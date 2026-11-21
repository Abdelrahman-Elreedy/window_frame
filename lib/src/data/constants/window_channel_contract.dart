/// The agreement between Dart and the native plugin: channel, method, event,
/// argument and result names.
///
/// The native twin of this file is `windows/src/presentation/channel_contract.h`.
/// Change a name in both files, or the two sides stop understanding each other.
abstract final class WindowChannelContract {
  static const String channelName = 'window_frame';

  // Dart -> native commands.
  static const String initializeMethod = 'initialize';
  static const String minimizeMethod = 'minimizeWindow';
  static const String maximizeMethod = 'maximizeWindow';
  static const String restoreMethod = 'restoreWindow';
  static const String toggleMaximizeMethod = 'toggleMaximizeWindow';
  static const String requestCloseMethod = 'requestWindowClose';
  static const String startDragMethod = 'startWindowDrag';
  static const String setMinimumSizeMethod = 'setMinimumWindowSize';

  // Native -> Dart events.
  static const String maximizedStateChangedEvent = 'onMaximizedStateChanged';
  static const String activationStateChangedEvent = 'onActivationStateChanged';

  // Argument keys.
  static const String minimumWidthKey = 'minimumWidth';
  static const String minimumHeightKey = 'minimumHeight';
  static const String startMaximizedKey = 'startMaximized';
  static const String customFrameKey = 'customFrame';
  static const String frameBorderWidthKey = 'frameBorderWidth';

  // Result keys.
  static const String customFrameActiveKey = 'customFrameActive';
  static const String isMaximizedKey = 'isMaximized';
  static const String isWindowActiveKey = 'isWindowActive';
  static const String applicationTitleKey = 'applicationTitle';

  // Error codes.
  static const String windowNotReadyErrorCode = 'window_not_ready';
}
