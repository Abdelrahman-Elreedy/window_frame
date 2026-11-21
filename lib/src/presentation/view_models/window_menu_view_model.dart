import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_session.dart';

/// A part of the title bar that can open a window menu at a point (the empty
/// bar, the leading icon). The view model asks them when a menu is already open
/// and the user right-clicks somewhere else, so the new menu opens at once.
abstract interface class WindowMenuRegion {
  /// Opens this region's menu at [globalPosition] and returns `true`, or returns
  /// `false` when the point is not for this region.
  bool openMenuAt(Offset globalPosition);

  /// A left-click at [globalPosition] has just closed a menu (the menu swallowed
  /// the click). A region that handles double-clicks can count it as the first
  /// click of one. A control of the bar (button, tab, text field) under the point
  /// gets the click replayed, so it works as if the menu had not been there.
  /// [device] is the id of the mouse that clicked.
  void noteDismissingClick(Offset globalPosition, int device);

  /// Whether pressing [globalPosition] and dragging should move the window:
  /// `true` on the empty part of the bar, `false` on the icon, and `null` when
  /// the point is not in this region at all.
  bool? canDragWindowAt(Offset globalPosition);

  /// The user pressed [globalPosition] with [buttons] while a menu is open. A
  /// region that opens its own menu on a press (the icon) calls [closeOpenMenu],
  /// opens its menu and returns `true`; the others return `false`.
  bool handlePressWhileMenuOpen(
    Offset globalPosition,
    int buttons,
    VoidCallback closeOpenMenu,
  );
}

/// State and commands of the window menus, for the views.
///
/// It keeps the regions of the title bar that can open a menu, tells the views
/// which region owns a point, creates the [WindowMenuSession] of every open menu
/// and exposes what the standard entries need (is the window maximized, and the
/// window commands). This class knows no widget: the entries themselves, with
/// their icons, are built by the view (`buildWindowMenuEntries`).
class WindowMenuViewModel {
  WindowMenuViewModel(this._windowFrameViewModel);

  final WindowFrameViewModel _windowFrameViewModel;
  final List<WindowMenuRegion> _regions = <WindowMenuRegion>[];

  /// Whether the window is maximized right now (Restore is only available while
  /// maximized, Maximize only while not).
  bool get isMaximized => _windowFrameViewModel.isMaximized.value;

  Future<void> restore() => _windowFrameViewModel.restore();

  Future<void> minimize() => _windowFrameViewModel.minimize();

  Future<void> maximize() => _windowFrameViewModel.maximize();

  Future<void> requestClose() => _windowFrameViewModel.requestClose();

  int _openMenuCount = 0;

  /// Whether a window menu is open right now. The keyboard shortcuts of the
  /// entries do nothing while it is.
  bool get isMenuOpen => _openMenuCount > 0;

  void menuOpened() => _openMenuCount++;

  void menuClosed() {
    if (_openMenuCount > 0) _openMenuCount--;
  }

  void registerRegion(WindowMenuRegion region) => _regions.add(region);

  void unregisterRegion(WindowMenuRegion region) => _regions.remove(region);

  /// The decisions of a menu that is about to open (see [WindowMenuSession]).
  WindowMenuSession createSession({
    Rect? doubleClickCloseZone,
    Rect? anchorBounds,
    bool openedByPress = false,
  }) {
    return WindowMenuSession(
      canDragWindowAt: canDragWindowAt,
      doubleClickCloseZone: doubleClickCloseZone,
      anchorBounds: anchorBounds,
      openedByPress: openedByPress,
    );
  }

  /// Opens the menu of the region that owns [globalPosition]. The most
  /// recently registered region (the innermost widget) is asked first.
  bool openMenuAt(Offset globalPosition) {
    for (final WindowMenuRegion region in _regions.reversed.toList()) {
      if (region.openMenuAt(globalPosition)) return true;
    }
    return false;
  }

  /// A press happened while a menu is open: the region under it that opens its own
  /// menu on a press takes over (the open menu is closed with [closeOpenMenu]).
  bool openMenuOnPress(
    Offset globalPosition,
    int buttons,
    VoidCallback closeOpenMenu,
  ) {
    for (final WindowMenuRegion region in _regions.reversed.toList()) {
      if (region.handlePressWhileMenuOpen(
        globalPosition,
        buttons,
        closeOpenMenu,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Whether a press at [globalPosition] on the title bar is a window drag. The
  /// innermost region that owns the point answers.
  bool canDragWindowAt(Offset globalPosition) {
    for (final WindowMenuRegion region in _regions.reversed.toList()) {
      final bool? answer = region.canDragWindowAt(globalPosition);
      if (answer != null) return answer;
    }
    return false;
  }

  /// Whether some region (the drag area of the bar, the icon) owns
  /// [globalPosition]. Outside every region (the action buttons, the caption
  /// buttons, the page below the bar) nobody handles a click that closed a menu.
  bool isInsideRegion(Offset globalPosition) {
    for (final WindowMenuRegion region in _regions.toList()) {
      if (region.canDragWindowAt(globalPosition) != null) return true;
    }
    return false;
  }

  /// Tells every region that a left-click closed a menu at [globalPosition].
  void noteDismissingClick(Offset globalPosition, int device) {
    for (final WindowMenuRegion region in _regions.toList()) {
      region.noteDismissingClick(globalPosition, device);
    }
  }
}
