import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:window_frame/src/presentation/models/window_menu.dart';

/// Makes the `activator` of the menu entries work as keyboard shortcuts.
///
/// It sits ABOVE the window's Navigator, so a key pressed anywhere in the app
/// (a page, a dialog, a text field) bubbles up to it after the widget that has
/// the focus has had its chance: a text field keeps `Ctrl+C`, and a shortcut
/// only runs when nothing below wanted the key.
///
/// The entries are asked for at the moment a key is pressed ([entriesProvider]),
/// so an entry that was disabled a moment ago, or whose `onPressed` changed, is
/// always judged by its current state.
class WindowMenuShortcuts extends StatelessWidget {
  const WindowMenuShortcuts({
    super.key,
    required this.entriesProvider,
    required this.child,
    this.isBlocked,
  });

  /// The entries that may own a shortcut, right now.
  final List<WindowMenuEntry> Function() entriesProvider;

  /// While it returns `true` no shortcut runs (a window menu is open, or a dialog
  /// covers the window).
  final bool Function()? isBlocked;

  final Widget child;

  static final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.capsLock,
    LogicalKeyboardKey.numLock,
  };

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Pressing a modifier alone is never a shortcut.
    if (_modifierKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    // Typing must stay cheap: a key that produces a character without Ctrl, Alt
    // or Win cannot be a shortcut (it would fight with typing), so the entries
    // are not even built for it.
    final bool hasCommandModifier =
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed;
    if (!hasCommandModifier && event.character != null) {
      return KeyEventResult.ignored;
    }
    if (isBlocked?.call() ?? false) return KeyEventResult.ignored;

    for (final WindowMenuEntry entry in entriesProvider()) {
      if (entry is! WindowMenuItem || !entry.isEnabled) continue;
      final ShortcutActivator? activator = entry.activator;
      if (activator == null || !activator.accepts(event, keyboard)) continue;
      // A held key repeats: swallow the repeats, run the entry once.
      if (event is KeyDownEvent) entry.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: child,
    );
  }
}
