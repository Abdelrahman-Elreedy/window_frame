import 'dart:ui' show Offset, Rect;

import 'package:flutter/gestures.dart'
    show kDoubleTapTimeout, kPrimaryButton, kSecondaryMouseButton;

/// What the view must do after a mouse press while a menu is open.
enum MenuPressOutcome {
  /// Nothing.
  none,

  /// Close the menu now (a right-click landed on the menu itself).
  closeMenu,

  /// Hide the menu at once; the window close dialog follows when it is gone.
  hideForWindowClose,
}

/// What the view must do after a mouse release while a menu is open.
enum MenuReleaseOutcome {
  /// Nothing.
  none,

  /// Run the entry under the mouse (the menu follows a drag from the icon).
  runItem,

  /// Close the menu.
  closeMenu,
}

/// What the view must do once a menu is gone.
enum MenuClosedOutcome {
  /// Nothing more.
  nothing,

  /// Run the entry the user picked.
  runItem,

  /// Ask the window to close (a double-click on the icon).
  requestWindowClose,

  /// Open the menu of the place that was right-clicked.
  reopenMenu,

  /// A left-click closed the menu: tell the title bar about it.
  noteDismissingClick,
}

/// The decisions of ONE open window menu.
///
/// The barrier of a menu swallows the mouse, so the view watches the mouse and
/// feeds every press, move and release to this class. It remembers what
/// happened and answers what to do: close, hide, run an entry, start a window
/// drag, reopen elsewhere. It knows no widget, no route and no navigator; the
/// view only translates events into plain values and does what is answered.
class WindowMenuSession {
  WindowMenuSession({
    required bool Function(Offset globalPosition) canDragWindowAt,
    this.doubleClickCloseZone,
    this.anchorBounds,
    this.openedByPress = false,
    Duration Function()? clock,
  }) : _canDragWindowAt = canDragWindowAt,
       _clock = clock ?? _stopwatchClock() {
    _openedAt = _clock();
  }

  /// How far the mouse must move (logical px) before pressing the bar counts as
  /// a drag.
  static const double windowDragDistance = 6;

  /// A second left-click here, soon after the menu opened, closes the window
  /// (a double-click on the icon).
  final Rect? doubleClickCloseZone;

  /// The icon of this menu: clicking it again just closes the menu.
  final Rect? anchorBounds;

  /// The menu opened the moment the icon was pressed (the button is still down),
  /// so it follows the mouse until the release.
  final bool openedByPress;

  final bool Function(Offset globalPosition) _canDragWindowAt;
  final Duration Function() _clock;
  Duration _openedAt = Duration.zero;

  Offset? _reopenPosition;
  Offset? _dismissingClick;
  int _dismissingDevice = 0;
  bool _closeRequested = false;
  bool _dragStarted = false;
  bool _releaseHandled = false;
  bool _handedOver = false;
  int? _pressedPointer;
  Offset? _pressedPosition;

  static Duration Function() _stopwatchClock() {
    final Stopwatch stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  /// Another menu has taken over: this session ignores everything from now on.
  bool get handedOver => _handedOver;

  /// Where a right-click happened while the menu was open (or `null`).
  Offset? get reopenPosition => _reopenPosition;

  /// Where a left-click closed the menu (or `null`).
  Offset? get dismissingClick => _dismissingClick;

  /// The mouse that made [dismissingClick].
  int get dismissingDevice => _dismissingDevice;

  bool get _isQuick => _clock() - _openedAt <= kDoubleTapTimeout;

  bool _isInDoubleClickZone(Offset position) {
    final Rect? zone = doubleClickCloseZone;
    return zone != null && zone.contains(position) && _isQuick;
  }

  /// A press OUTSIDE the menu, seen before the barrier: should the view offer it
  /// to the title bar so the icon can take over with its own menu?
  bool shouldOfferHandOver({required Offset position, required int buttons}) {
    if (_handedOver) return false;
    final bool isLeftButton = buttons == kPrimaryButton;
    // A quick second click on the icon closes the window.
    if (isLeftButton && _isInDoubleClickZone(position)) return false;
    // The icon of THIS menu: clicking it again just closes the menu.
    if (isLeftButton && (anchorBounds?.contains(position) ?? false)) {
      return false;
    }
    return true;
  }

  /// Called when the title bar took over with another menu.
  void markHandedOver() => _handedOver = true;

  /// A mouse button went down.
  MenuPressOutcome onPointerDown({
    required Offset position,
    required int buttons,
    required int pointer,
    required int device,
    required bool isOnMenu,
  }) {
    if (buttons == kSecondaryMouseButton) {
      _reopenPosition = position;
      // The menu opens AT the mouse, so the next right-click often lands on the
      // menu itself. The menu swallows that click and its barrier never sees it.
      return isOnMenu ? MenuPressOutcome.closeMenu : MenuPressOutcome.none;
    }
    if (isOnMenu || buttons != kPrimaryButton) return MenuPressOutcome.none;

    if (_isInDoubleClickZone(position)) {
      _closeRequested = true;
      return MenuPressOutcome.hideForWindowClose;
    }
    // A left-click outside closes the menu. The barrier swallows it, so the bar
    // is told afterwards: it may be the first click of a double-click, or the
    // start of a window drag.
    _dismissingClick = position;
    _dismissingDevice = device;
    _pressedPointer = pointer;
    _pressedPosition = position;
    return MenuPressOutcome.none;
  }

  /// The mouse moved. Returns `true` when the bar was pressed while the menu was
  /// open and has now been dragged: the view hides the menu and starts moving
  /// the window.
  bool onPointerMove({required Offset position, required int pointer}) {
    final Offset? start = _pressedPosition;
    if (start == null ||
        _dragStarted ||
        pointer != _pressedPointer ||
        (position - start).distance < windowDragDistance ||
        !_canDragWindowAt(start)) {
      return false;
    }
    _dragStarted = true;
    _dismissingClick = null;
    return true;
  }

  /// A mouse button went up.
  MenuReleaseOutcome onPointerUp({
    required Offset position,
    required int pointer,
    required bool isOverEnabledItem,
    required bool isOnMenu,
  }) {
    if (pointer == _pressedPointer) _pressedPosition = null;
    if (!openedByPress || _releaseHandled) return MenuReleaseOutcome.none;

    _releaseHandled = true;
    if (isOverEnabledItem) return MenuReleaseOutcome.runItem;
    final bool isOnAnchor = anchorBounds?.contains(position) ?? false;
    if (!isOnMenu && !isOnAnchor) return MenuReleaseOutcome.closeMenu;
    return MenuReleaseOutcome.none;
  }

  /// The system cancelled a pointer.
  void onPointerCancel(int pointer) {
    if (pointer == _pressedPointer) _pressedPosition = null;
  }

  /// What to do once the menu is gone. [hasSelectedItem]: the user picked an entry.
  MenuClosedOutcome afterClose({required bool hasSelectedItem}) {
    if (_handedOver) return MenuClosedOutcome.nothing;
    if (hasSelectedItem) return MenuClosedOutcome.runItem;
    if (_closeRequested) return MenuClosedOutcome.requestWindowClose;
    if (_reopenPosition != null) return MenuClosedOutcome.reopenMenu;
    if (_dismissingClick != null) return MenuClosedOutcome.noteDismissingClick;
    return MenuClosedOutcome.nothing;
  }
}
