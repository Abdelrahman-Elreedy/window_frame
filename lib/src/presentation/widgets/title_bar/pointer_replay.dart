import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart';

/// Sends a complete left click (press + release) at [position], as if the user
/// had clicked again. Used after a menu closes: the barrier of the menu swallowed
/// the user's click, so the widget under the mouse never saw it. [device] is the
/// id of the mouse that clicked and [viewId] the view of the window.
void replayLeftClick(Offset position, int device, int viewId) {
  final GestureBinding binding = GestureBinding.instance;
  final int pointer = _nextReplayPointer++;
  binding.handlePointerEvent(
    PointerDownEvent(
      viewId: viewId,
      pointer: pointer,
      device: device,
      kind: PointerDeviceKind.mouse,
      position: position,
      buttons: kPrimaryButton,
    ),
  );
  binding.handlePointerEvent(
    PointerUpEvent(
      viewId: viewId,
      pointer: pointer,
      device: device,
      kind: PointerDeviceKind.mouse,
      position: position,
    ),
  );
}

/// Ids for replayed clicks: far from the ids the engine hands out.
int _nextReplayPointer = 0x70000000;
