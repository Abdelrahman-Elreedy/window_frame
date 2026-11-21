import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, LogicalKeyboardKey, KeyUpEvent;

import 'package:window_frame/src/presentation/models/window_menu.dart';
import 'package:window_frame/src/presentation/view_models/double_click_detector.dart';
import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_session.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_view_model.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/pointer_replay.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_menu_entries.dart';

/// Set to `true` to print what a window menu sees (opening, the mouse release of
/// a drag from the icon). For bug reports; keep it `false`.
const bool _debugMenuInput = false;

void _log(String message) {
  if (_debugMenuInput) debugPrint('[window_frame menu] $message');
}

/// Shows [menu] at [globalPosition] and runs the entry the user picks.
///
/// [context] must live inside the window's Navigator (any widget of the title
/// bar does), so the menu opens on top of the whole window.
///
/// While the menu is open it behaves like a native Windows menu:
///
/// * A right-click somewhere else closes it and opens the menu that belongs to
///   that place, in one click.
/// * Pressing the empty title bar and dragging closes it and moves the window.
/// * If [doubleClickCloseZone] is given and the user clicks inside it a second
///   time, quickly, the window is asked to close (a double-click on the icon).
/// * If [openedByPress] is true (the menu opened the moment the icon was pressed,
///   and the button is still down), the menu follows the mouse: releasing the
///   button over an entry runs it, releasing over [anchorBounds] (the icon) or
///   over the menu leaves it open, releasing anywhere else closes it. A plain
///   click is the same thing with the release over the icon.
///
/// Why the menu must open on the press and not later: the Navigator cancels every
/// active pointer when a route is pushed, and Flutter then drops the rest of that
/// pointer's events (moves and release). Pushed from the press handler, which runs
/// before the Navigator has noted the pointer, nothing is cancelled.
/// * It closes by itself when the window loses the focus or changes state
///   (maximized, restored).
Future<void> showWindowMenu({
  required BuildContext context,
  required Offset globalPosition,
  required WindowMenu menu,
  Rect? doubleClickCloseZone,
  Rect? anchorBounds,
  bool openedByPress = false,
}) async {
  final WindowFrameServices services = WindowFrameServicesProvider.servicesOf(
    context,
  );
  final WindowMenuViewModel menuViewModel = services.windowMenuViewModel;
  final WindowFrameViewModel windowViewModel = services.windowFrameViewModel;
  final List<WindowMenuEntry> entries = buildWindowMenuEntries(
    context,
    menu,
    menuViewModel,
  );
  if (entries.isEmpty) return;

  final NavigatorState navigator = Navigator.of(context);
  final int viewId = View.of(context).viewId;
  final RenderObject? overlay = navigator.overlay?.context.findRenderObject();
  if (overlay is! RenderBox) return;

  // Every decision (what a press, a move or a release means) is made by the
  // session, which knows no widget. This function only feeds it the mouse and
  // does what it answers.
  final WindowMenuSession session = menuViewModel.createSession(
    doubleClickCloseZone: doubleClickCloseZone,
    anchorBounds: anchorBounds,
    openedByPress: openedByPress,
  );

  // Built below: the route calls handlePressOutside, which uses the route.
  late final _WindowMenuRoute route;

  _log('open: openedByPress=$openedByPress anchorBounds=$anchorBounds');

  void closeMenu() {
    if (route.isCurrent) navigator.pop();
  }

  // A press OUTSIDE the menu, seen before the barrier and the Navigator see it. If
  // it is on the icon, this menu gives way to the icon's menu at once: left,
  // right, or press-and-drag, like switching between two native menus. It must
  // happen here: from the barrier's side the Navigator already holds the pointer
  // and would cancel it when the new menu is pushed.
  void handlePressOutside(PointerDownEvent event) {
    if (!route.isCurrent) return;
    if (!session.shouldOfferHandOver(
      position: event.position,
      buttons: event.buttons,
    )) {
      return;
    }
    menuViewModel.openMenuOnPress(event.position, event.buttons, () {
      session.markHandedOver();
      closeMenu();
    });
  }

  route = _WindowMenuRoute(
    anchor: overlay.globalToLocal(globalPosition),
    entries: entries,
    dismissLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    onPressOutside: handlePressOutside,
  );

  // The barrier of the menu swallows the clicks, so the mouse is watched here.
  void watchPointer(PointerEvent event) {
    if (session.handedOver) return; // another menu has taken over
    if (event is! PointerMoveEvent) {
      _log('pointer ${event.runtimeType} at ${event.position}');
    }
    if (event is PointerDownEvent) {
      final MenuPressOutcome outcome = session.onPointerDown(
        position: event.position,
        buttons: event.buttons,
        pointer: event.pointer,
        device: event.device,
        isOnMenu: route.containsGlobalPoint(event.position),
      );
      switch (outcome) {
        case MenuPressOutcome.closeMenu:
          closeMenu();
        case MenuPressOutcome.hideForWindowClose:
          route.hide(); // the menu disappears at once; only the dialog follows
        case MenuPressOutcome.none:
          break;
      }
    } else if (event is PointerMoveEvent) {
      if (session.onPointerMove(
        position: event.position,
        pointer: event.pointer,
      )) {
        // The bar was pressed while the menu was open and now it is dragged:
        // the menu goes away and the window follows the mouse.
        route.hide();
        closeMenu();
        unawaited(windowViewModel.startDrag());
      }
    } else if (event is PointerUpEvent) {
      final WindowMenuItem? item = route.itemAt(event.position);
      final bool isOnMenu = route.containsGlobalPoint(event.position);
      final MenuReleaseOutcome outcome = session.onPointerUp(
        position: event.position,
        pointer: event.pointer,
        isOverEnabledItem: item != null,
        isOnMenu: isOnMenu,
      );
      _log('release: item=${item?.label} onMenu=$isOnMenu -> $outcome');
      switch (outcome) {
        case MenuReleaseOutcome.runItem:
          if (route.isCurrent) navigator.pop(item);
        case MenuReleaseOutcome.closeMenu:
          closeMenu();
        case MenuReleaseOutcome.none:
          break;
      }
    } else if (event is PointerCancelEvent) {
      session.onPointerCancel(event.pointer);
    }
  }

  final PointerRouter pointerRouter = GestureBinding.instance.pointerRouter;
  // Start watching only AFTER the event that opened the menu has been delivered.
  // That right-click is still being routed right now: watched, it would count as
  // "a right-click somewhere else" and the menu would reopen when it closes.
  bool menuClosed = false;
  scheduleMicrotask(() {
    _log('watching the mouse (closed already: $menuClosed)');
    if (!menuClosed) pointerRouter.addGlobalRoute(watchPointer);
  });
  // A native menu closes when the window loses the focus or changes size.
  windowViewModel.isWindowActive.addListener(closeMenu);
  windowViewModel.isMaximized.addListener(closeMenu);

  WindowMenuItem? selectedItem;
  menuViewModel.menuOpened();
  try {
    selectedItem = await navigator.push<WindowMenuItem>(route);
  } finally {
    menuViewModel.menuClosed();
    menuClosed = true;
    pointerRouter.removeGlobalRoute(watchPointer);
    windowViewModel.isWindowActive.removeListener(closeMenu);
    windowViewModel.isMaximized.removeListener(closeMenu);
  }

  switch (session.afterClose(hasSelectedItem: selectedItem != null)) {
    case MenuClosedOutcome.nothing:
      break;
    case MenuClosedOutcome.runItem:
      selectedItem?.onPressed();
    case MenuClosedOutcome.requestWindowClose:
      unawaited(windowViewModel.requestClose());
    case MenuClosedOutcome.reopenMenu:
      {
        // The old menu keeps its barrier until it is removed: wait for it, or the
        // hit test of the new menu would hit that barrier.
        final Offset next = session.reopenPosition!;
        await route.completed;
        await WidgetsBinding.instance.endOfFrame;
        menuViewModel.openMenuAt(next);
      }
    case MenuClosedOutcome.noteDismissingClick:
      {
        final Offset click = session.dismissingClick!;
        final int device = session.dismissingDevice;
        await route.completed;
        await WidgetsBinding.instance.endOfFrame;
        menuViewModel.noteDismissingClick(click, device);
        // Outside the drag area and the icon (action buttons, caption buttons,
        // the page below the bar) nobody replays the swallowed click: do it
        // here, so the widget under the mouse gets it (a text field takes the
        // focus).
        if (!menuViewModel.isInsideRegion(click)) {
          replayLeftClick(click, device, viewId);
        }
      }
  }
}

/// The route of a window menu: a fast fade-in, no dimmed background.
class _WindowMenuRoute extends PopupRoute<WindowMenuItem> {
  _WindowMenuRoute({
    required this.anchor,
    required this.entries,
    required this.dismissLabel,
    required this.onPressOutside,
  });

  /// Called with every press that lands outside the menu, before the barrier.
  final ValueChanged<PointerDownEvent> onPressOutside;

  final Offset anchor;
  final List<WindowMenuEntry> entries;
  final String dismissLabel;
  final GlobalKey surfaceKey = GlobalKey();

  /// One key per entry, to find the item under the mouse (see [itemAt]).
  late final List<GlobalKey> itemKeys = List<GlobalKey>.generate(
    entries.length,
    (int _) => GlobalKey(),
  );

  /// The enabled item under [point], or `null`.
  WindowMenuItem? itemAt(Offset point) {
    for (int index = 0; index < entries.length; index++) {
      final WindowMenuEntry entry = entries[index];
      if (entry is! WindowMenuItem || !entry.isEnabled) continue;
      final RenderObject? renderObject = itemKeys[index].currentContext
          ?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;
      final Rect bounds =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (bounds.contains(point)) return entry;
    }
    return null;
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => dismissLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 90);

  @override
  Duration get reverseTransitionDuration => Duration.zero; // vanish at once, like a native menu

  final ValueNotifier<bool> _isHidden = ValueNotifier<bool>(false);

  /// Makes the menu invisible at once (its route is popped a moment later).
  void hide() => _isHidden.value = true;

  @override
  void dispose() {
    _isHidden.dispose();
    super.dispose();
  }

  /// Whether [point] is on the menu itself (not on the barrier around it).
  bool containsGlobalPoint(Offset point) {
    final RenderObject? renderObject = surfaceKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    return (renderObject.localToGlobal(Offset.zero) & renderObject.size)
        .contains(point);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      // A translucent Listener over the whole window: it sees every press before
      // the barrier below it does.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        child: CustomSingleChildLayout(
          delegate: _WindowMenuLayoutDelegate(anchor),
          child: FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isHidden,
              builder: (BuildContext context, bool isHidden, Widget? surface) =>
                  Opacity(opacity: isHidden ? 0 : 1, child: surface),
              child: _WindowMenuSurface(
                key: surfaceKey,
                entries: entries,
                itemKeys: itemKeys,
                onSelected: (WindowMenuItem item) =>
                    Navigator.of(context).pop(item),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (containsGlobalPoint(event.position)) return;
    onPressOutside(event);
  }
}

/// Puts the menu at the anchor; near an edge of the window it moves back inside
/// (or opens upwards) so it is never cut off.
class _WindowMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _WindowMenuLayoutDelegate(this.anchor);

  static const double _margin = 8;

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(const EdgeInsets.all(_margin));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = anchor.dx;
    double y = anchor.dy;
    if (x + childSize.width > size.width - _margin) {
      x = size.width - _margin - childSize.width;
    }
    if (y + childSize.height > size.height - _margin) {
      y = anchor.dy - childSize.height;
    }
    return Offset(math.max(_margin, x), math.max(_margin, y));
  }

  @override
  bool shouldRelayout(_WindowMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor;
}

/// The first letter (or the `mnemonic`) that chooses [item] from the keyboard.
String _mnemonicOf(WindowMenuItem item) {
  final String source = (item.mnemonic != null && item.mnemonic!.isNotEmpty)
      ? item.mnemonic!
      : item.label;
  if (source.isEmpty) return '';
  return String.fromCharCode(source.runes.first).toLowerCase();
}

class _WindowMenuSurface extends StatefulWidget {
  const _WindowMenuSurface({
    super.key,
    required this.entries,
    required this.itemKeys,
    required this.onSelected,
  });

  final List<WindowMenuEntry> entries;
  final List<GlobalKey> itemKeys;
  final ValueChanged<WindowMenuItem> onSelected;

  @override
  State<_WindowMenuSurface> createState() => _WindowMenuSurfaceState();
}

class _WindowMenuSurfaceState extends State<_WindowMenuSurface> {
  /// The entry under the mouse or reached with the arrow keys: one highlight for
  /// both, like a native menu.
  int? _highlightedIndex;

  List<int> _enabledIndexes() {
    final List<int> result = <int>[];
    for (int index = 0; index < widget.entries.length; index++) {
      final WindowMenuEntry entry = widget.entries[index];
      if (entry is WindowMenuItem && entry.isEnabled) result.add(index);
    }
    return result;
  }

  void _highlight(int index) {
    setState(() => _highlightedIndex = index);
  }

  /// The mouse left [index]: it is no longer highlighted (unless the keyboard
  /// has moved the highlight elsewhere in the meantime).
  void _clearHighlight(int index) {
    if (_highlightedIndex != index) return;
    setState(() => _highlightedIndex = null);
  }

  void _select(int index) {
    final WindowMenuEntry entry = widget.entries[index];
    if (entry is WindowMenuItem && entry.isEnabled) widget.onSelected(entry);
  }

  void _moveHighlight(int step) {
    final List<int> enabled = _enabledIndexes();
    if (enabled.isEmpty) return;
    final int? current = _highlightedIndex;
    final int position = current == null ? -1 : enabled.indexOf(current);
    final int next = position < 0
        ? (step > 0 ? 0 : enabled.length - 1)
        : (position + step) % enabled.length;
    _highlight(enabled[next]);
  }

  /// A letter was typed: one item with that mnemonic runs, several take turns.
  bool _typeCharacter(String typed) {
    final String letter = String.fromCharCode(typed.runes.first).toLowerCase();
    final List<int> matches = <int>[];
    for (final int index in _enabledIndexes()) {
      final WindowMenuEntry entry = widget.entries[index];
      if (entry is WindowMenuItem && _mnemonicOf(entry) == letter) {
        matches.add(index);
      }
    }
    if (matches.isEmpty) return false;
    if (matches.length == 1) {
      _select(matches.first);
      return true;
    }
    final int? current = _highlightedIndex;
    final int next = matches.firstWhere(
      (int index) => current == null || index > current,
      orElse: () => matches.first,
    );
    _highlight(next);
    return true;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }

    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      final List<int> enabled = _enabledIndexes();
      if (enabled.isEmpty) return KeyEventResult.handled;
      _highlight(key == LogicalKeyboardKey.home ? enabled.first : enabled.last);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final int? index = _highlightedIndex;
      if (index == null) return KeyEventResult.ignored;
      _select(index);
      return KeyEventResult.handled;
    }

    // Escape, Tab... also carry a character: only real letters and digits count.
    final String? typed = event.character;
    if (typed == null || typed.trim().isEmpty) return KeyEventResult.ignored;
    final int firstCode = typed.runes.first;
    if (firstCode < 0x20 || firstCode == 0x7f) return KeyEventResult.ignored;
    return _typeCharacter(typed.trim())
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        elevation: 8,
        color: theme.popupMenuTheme.color ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 190),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int index = 0; index < widget.entries.length; index++)
                    _buildEntry(index),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(int index) {
    final WindowMenuEntry entry = widget.entries[index];
    if (entry is WindowMenuItem) {
      return _WindowMenuItemTile(
        key: widget.itemKeys[index],
        item: entry,
        isHighlighted: _highlightedIndex == index,
        onSelected: widget.onSelected,
        onHover: () => _highlight(index),
        onLeave: () => _clearHighlight(index),
      );
    }
    return const Divider(height: 9, thickness: 1);
  }
}

class _WindowMenuItemTile extends StatelessWidget {
  const _WindowMenuItemTile({
    super.key,
    required this.item,
    required this.isHighlighted,
    required this.onSelected,
    required this.onHover,
    required this.onLeave,
  });

  final WindowMenuItem item;
  final bool isHighlighted;
  final ValueChanged<WindowMenuItem> onSelected;
  final VoidCallback onHover;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = item.isEnabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    final String? shortcut = item.shortcutLabel;

    return InkWell(
      hoverColor: Colors.transparent,
      onTap: item.isEnabled ? () => onSelected(item) : null,
      onHover: (bool hovering) => hovering ? onHover() : onLeave(),
      child: Container(
        height: 32,
        color: isHighlighted && item.isEnabled
            ? theme.colorScheme.onSurface.withAlpha(20)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            SizedBox(width: 20, child: _buildIcon(context, textColor)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLabel(TextStyle(fontSize: 13, color: textColor)),
            ),
            if (shortcut != null) ...<Widget>[
              const SizedBox(width: 28),
              Text(
                shortcut,
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildIcon(BuildContext context, Color color) {
    final WindowMenuIconBuilder? iconBuilder = item.iconBuilder;
    if (iconBuilder != null) {
      return Center(child: iconBuilder(context, color));
    }
    final IconData? icon = item.icon;
    return icon == null ? null : Icon(icon, size: 16, color: color);
  }

  /// The label, with its mnemonic letter underlined (the letter that runs the
  /// entry from the keyboard).
  Widget _buildLabel(TextStyle style) {
    if (!item.isEnabled) {
      return Text(item.label, style: style);
    }
    final String letter = _mnemonicOf(item);
    final int at = letter.isEmpty
        ? -1
        : item.label.toLowerCase().indexOf(letter);
    if (at < 0 || at >= item.label.length) {
      return Text(item.label, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: item.label.substring(0, at)),
          TextSpan(
            text: item.label.substring(at, at + 1),
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: item.label.substring(at + 1)),
        ],
      ),
    );
  }
}

/// Makes its child open a window menu when the user clicks it with the left or
/// the right mouse button. The menu opens just under the child, like the icon
/// menu of a native window. Used for the leading widget of the title bar.
class WindowMenuTrigger extends StatefulWidget {
  const WindowMenuTrigger({super.key, required this.menu, required this.child});

  final WindowMenu menu;
  final Widget child;

  @override
  State<WindowMenuTrigger> createState() => _WindowMenuTriggerState();
}

class _WindowMenuTriggerState extends State<WindowMenuTrigger>
    implements WindowMenuRegion {
  /// Remembers a left-click on this icon that closed a menu that was already
  /// open. The next left-click on the icon, soon after, completes a
  /// double-click.
  final DoubleClickDetector _doubleClick = DoubleClickDetector();
  WindowMenuViewModel? _menuViewModel;

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
    // The left button opens the menu on the PRESS, like a native window, so the
    // menu can follow the mouse until the button is released (see
    // showWindowMenu). The right button opens it on release, as usual.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTap: () => _open(isPrimaryClick: false),
        child: widget.child,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) return;
    _open(isPrimaryClick: true, openedByPress: true);
  }

  Rect? _globalBounds() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _open({required bool isPrimaryClick, bool openedByPress = false}) {
    final Rect? bounds = _globalBounds();
    if (bounds == null) return;

    // The first click of a double-click only closed an open menu (see
    // noteDismissingClick); this is the second one: close the window instead of
    // opening the menu again.
    final bool isSecondClick =
        isPrimaryClick &&
        widget.menu.closeOnDoubleClick &&
        _doubleClick.isDoubleClickAt(bounds.center);
    _doubleClick.forget();
    if (isSecondClick) {
      unawaited(
        WindowFrameServicesProvider.windowFrameViewModelOf(
          context,
        ).requestClose(),
      );
      return;
    }
    unawaited(
      showWindowMenu(
        context: context,
        globalPosition: bounds.bottomLeft,
        menu: widget.menu,
        // A double left-click on the icon closes the window, like a native one.
        doubleClickCloseZone: isPrimaryClick && widget.menu.closeOnDoubleClick
            ? bounds
            : null,
        anchorBounds: bounds,
        openedByPress: openedByPress,
      ),
    );
  }

  @override
  bool openMenuAt(Offset globalPosition) {
    final Rect? bounds = _globalBounds();
    if (bounds == null || !bounds.contains(globalPosition)) return false;
    _open(isPrimaryClick: false);
    return true;
  }

  @override
  void noteDismissingClick(Offset globalPosition, int device) {
    final Rect? bounds = _globalBounds();
    if (bounds == null || !bounds.contains(globalPosition)) return;
    _doubleClick.note(bounds.center);
  }

  /// The icon: a press on it while another menu is open closes that menu and
  /// opens the icon's menu at once (left button: follows the mouse until the
  /// release; right button: just opens).
  @override
  bool handlePressWhileMenuOpen(
    Offset globalPosition,
    int buttons,
    VoidCallback closeOpenMenu,
  ) {
    final Rect? bounds = _globalBounds();
    if (bounds == null || !bounds.contains(globalPosition)) return false;
    if (buttons == kPrimaryButton) {
      closeOpenMenu();
      _open(isPrimaryClick: true, openedByPress: true);
      return true;
    }
    if (buttons == kSecondaryMouseButton) {
      closeOpenMenu();
      _open(isPrimaryClick: false);
      return true;
    }
    return false;
  }

  // The icon is not a drag handle (dragging it opens its menu).
  @override
  bool? canDragWindowAt(Offset globalPosition) {
    final Rect? bounds = _globalBounds();
    return bounds != null && bounds.contains(globalPosition) ? false : null;
  }
}
