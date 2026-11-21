import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:window_frame/src/presentation/view_models/double_click_detector.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_view_model.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/pointer_replay.dart';

/// Makes everything inside draggable to move the window.
///
/// It behaves like the title bar of a native window:
///
/// * Dragging an empty part (or a text) moves the window.
/// * A double-click on an empty part (or a text) maximizes / restores it.
/// * A right-click on an empty part calls [onContextMenuRequested].
/// * Buttons, tabs, text fields and every other widget that reacts to the
///   mouse are left alone: pressing them never moves the window, double-clicking
///   them never maximizes it, right-clicking them never opens the bar menu, and
///   they are not delayed. Widgets that only DRAW something (a progress bar, an
///   icon without `onPressed`) count as empty space; wrap them in a
///   [WindowNoDragArea] to keep them out of all of this.
class WindowDragArea extends StatefulWidget {
  const WindowDragArea({
    super.key,
    required this.child,
    this.doubleTapToToggleMaximize = true,
    this.isDraggable = true,
    this.onContextMenuRequested,
  });

  final Widget child;

  /// A double-click on an empty part maximizes / restores the window.
  final bool doubleTapToToggleMaximize;

  /// Dragging an empty part moves the window.
  final bool isDraggable;

  /// Called with the global position of a right-click on an empty part.
  final ValueChanged<Offset>? onContextMenuRequested;

  @override
  State<WindowDragArea> createState() => _WindowDragAreaState();
}

class _WindowDragAreaState extends State<WindowDragArea>
    implements WindowMenuRegion {
  /// Two clicks count as a double-click when they are this close (logical px).
  static const double _doubleClickDistance = 8;

  final DoubleClickDetector _doubleClick = DoubleClickDetector(
    maxDistance: _doubleClickDistance,
  );
  WindowMenuViewModel? _menuViewModel;
  _PointerTarget _pressedTarget = const _PointerTarget.empty();

  @override
  void initState() {
    super.initState();
    _menuViewModel = WindowFrameServicesProvider.maybeServicesOf(
      context,
    )?.windowMenuViewModel;
    _menuViewModel?.registerRegion(this);
  }

  @override
  void dispose() {
    _menuViewModel?.unregisterRegion(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Two ways of reading the mouse, each for what it does best:
    //  * a raw Listener sees every press at once, to find out what is under
    //    the pointer (and to open the right-click menu);
    //  * onTapUp goes through the gesture arena, so a button or a tab under
    //    the pointer wins the tap by itself. A double-tap recognizer would delay
    //    every tap inside the bar, which is why the double-click is counted by
    //    hand from two taps.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: _handleTapUp,
        onPanStart: (DragStartDetails _) => _handlePanStart(),
        child: _DragAreaContent(child: widget.child),
      ),
    );
  }

  void _handlePanStart() {
    if (!widget.isDraggable || _pressedTarget.isInteractive) return;
    WindowFrameServicesProvider.windowFrameViewModelOf(context).startDrag();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pressedTarget = _inspectTargetAt(event.position);
    if (event.buttons != kSecondaryMouseButton) return;

    _doubleClick.forget();
    if (!_pressedTarget.isInteractive) {
      widget.onContextMenuRequested?.call(event.position);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.doubleTapToToggleMaximize || _pressedTarget.isInteractive) {
      _doubleClick.forget();
      return;
    }
    if (_doubleClick.register(details.globalPosition)) {
      WindowFrameServicesProvider.windowFrameViewModelOf(
        context,
      ).toggleMaximize();
    }
  }

  /// Called by the menu view model when a menu is open and the user right-clicks
  /// elsewhere: if the point is an empty part of this bar, its menu opens.
  @override
  bool openMenuAt(Offset globalPosition) {
    final ValueChanged<Offset>? openMenu = widget.onContextMenuRequested;
    final RenderObject? renderObject = context.findRenderObject();
    if (openMenu == null || renderObject is! RenderBox) return false;
    if (!renderObject.hasSize) return false;

    final Rect bounds =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (!bounds.contains(globalPosition)) return false;
    if (_inspectTargetAt(globalPosition).isInteractive) return false;

    openMenu(globalPosition);
    return true;
  }

  // The empty bar opens its menu on a right-click RELEASE, after the open menu is
  // gone (openMenuAt); only the icon takes over on the press.
  @override
  bool handlePressWhileMenuOpen(
    Offset globalPosition,
    int buttons,
    VoidCallback closeOpenMenu,
  ) => false;

  @override
  bool? canDragWindowAt(Offset globalPosition) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final Rect bounds =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return bounds.contains(globalPosition) ? widget.isDraggable : null;
  }

  /// A left-click closed a menu on this bar. The menu swallowed it, but it still
  /// counts as the first click of a double-click on an empty part of the bar.
  @override
  void noteDismissingClick(Offset globalPosition, int device) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final Rect bounds =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (!bounds.contains(globalPosition)) return;

    // A button, tab or text field: the menu swallowed the click, so it is
    // replayed now and the control reacts (a text field takes the focus).
    if (_inspectTargetAt(globalPosition).isInteractive) {
      replayLeftClick(globalPosition, device, View.of(context).viewId);
      return;
    }
    if (!widget.doubleTapToToggleMaximize) return;

    _doubleClick.note(globalPosition);
  }

  /// Finds out what is under the pointer, with the same hit test Flutter runs,
  /// so the answer matches what the user sees. Only the widgets INSIDE this
  /// drag area count: the walk stops at the boundary that wraps the child.
  _PointerTarget _inspectTargetAt(Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      globalPosition,
      View.of(context).viewId,
    );

    bool isInteractive = false;
    bool isNoDragArea = false;
    // The path starts at the deepest widget and walks up to the root.
    for (final HitTestEntry<HitTestTarget> entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target is _RenderDragAreaContent) break;

      if (target is _RenderNoDragArea) {
        isNoDragArea = true;
        isInteractive = true;
      } else if (target is RenderPointerListener) {
        // GestureDetector, InkWell, buttons, text fields... all listen to the
        // pointer through a Listener.
        if (target.onPointerDown != null) isInteractive = true;
      } else if (target is RenderSemanticsGestureHandler) {
        if (target.onTap != null) isInteractive = true;
      } else if (target is RenderMouseRegion) {
        // A widget that asks for a special cursor (hand, I-beam...).
        final MouseCursor cursor = target.cursor;
        if (cursor != MouseCursor.defer && cursor != SystemMouseCursors.basic) {
          isInteractive = true;
        }
      }
    }
    return _PointerTarget(
      isInteractive: isInteractive,
      isNoDragArea: isNoDragArea,
    );
  }
}

/// What was under the pointer when it was pressed.
class _PointerTarget {
  const _PointerTarget({
    required this.isInteractive,
    required this.isNoDragArea,
  });

  const _PointerTarget.empty() : isInteractive = false, isNoDragArea = false;

  /// A control that reacts to the mouse itself (or a [WindowNoDragArea]).
  final bool isInteractive;

  /// A [WindowNoDragArea].
  final bool isNoDragArea;
}

/// Wraps the child of a drag area, to mark where "inside" starts in a hit test.
class _DragAreaContent extends SingleChildRenderObjectWidget {
  const _DragAreaContent({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDragAreaContent();
}

class _RenderDragAreaContent extends RenderProxyBox {
  // Always part of the hit-test path, even over empty space.
  @override
  bool hitTestSelf(Offset position) => true;
}

/// Keeps its child out of the drag area of the title bar: pressing it never
/// moves the window, a double-click on it never maximizes the window and a
/// right-click on it never opens the bar menu.
///
/// Buttons, tabs, text fields and widgets that listen to the mouse do not need
/// it (they are detected by themselves). Use it for a widget that only draws
/// something and should not behave like empty space: a progress bar, a status
/// chip, an image.
class WindowNoDragArea extends SingleChildRenderObjectWidget {
  const WindowNoDragArea({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoDragArea();
}

/// The marker that [WindowDragArea] looks for in the hit test.
class _RenderNoDragArea extends RenderProxyBox {
  // The whole box counts as "hit", even where the child draws nothing.
  @override
  bool hitTestSelf(Offset position) => true;
}
