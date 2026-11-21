#ifndef WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CONTRACT_H_
#define WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CONTRACT_H_

namespace window_frame::presentation::channel_contract {

// The agreement between the native plugin and Dart: channel, method, event,
// argument and result names.
//
// The Dart twin of this file is
// lib/src/data/constants/window_channel_contract.dart. Change a name in both
// files, or the two sides stop understanding each other.

inline constexpr char kChannelName[] = "window_frame";

// Dart -> native commands.
inline constexpr char kInitializeMethod[] = "initialize";
inline constexpr char kMinimizeMethod[] = "minimizeWindow";
inline constexpr char kMaximizeMethod[] = "maximizeWindow";
inline constexpr char kRestoreMethod[] = "restoreWindow";
inline constexpr char kToggleMaximizeMethod[] = "toggleMaximizeWindow";
inline constexpr char kRequestCloseMethod[] = "requestWindowClose";
inline constexpr char kStartDragMethod[] = "startWindowDrag";
inline constexpr char kSetMinimumSizeMethod[] = "setMinimumWindowSize";

// Native -> Dart events.
inline constexpr char kMaximizedStateChangedEvent[] = "onMaximizedStateChanged";
inline constexpr char kActivationStateChangedEvent[] =
    "onActivationStateChanged";

// Argument keys.
inline constexpr char kMinimumWidthKey[] = "minimumWidth";
inline constexpr char kMinimumHeightKey[] = "minimumHeight";
inline constexpr char kStartMaximizedKey[] = "startMaximized";
inline constexpr char kCustomFrameKey[] = "customFrame";
inline constexpr char kFrameBorderWidthKey[] = "frameBorderWidth";

// Result keys.
inline constexpr char kCustomFrameActiveKey[] = "customFrameActive";
inline constexpr char kIsMaximizedKey[] = "isMaximized";
inline constexpr char kIsWindowActiveKey[] = "isWindowActive";
inline constexpr char kApplicationTitleKey[] = "applicationTitle";

// Error codes.
inline constexpr char kWindowNotReadyErrorCode[] = "window_not_ready";

}  // namespace window_frame::presentation::channel_contract

#endif  // WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CONTRACT_H_
