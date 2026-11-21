import 'package:flutter/widgets.dart';

import 'package:window_frame/src/presentation/models/shortcut_label.dart';

/// Builds the entries of a window menu.
///
/// [systemEntries] are the standard Windows entries (Restore, Minimize,
/// Maximize, Close), already enabled or disabled for the current window state.
/// Return them as they are, add your own around them, or ignore them and
/// return only yours:
///
/// ```dart
/// WindowMenu(
///   itemsBuilder: (context, systemEntries) => <WindowMenuEntry>[
///     WindowMenuItem(
///       label: 'Settings',
///       activator: const SingleActivator(LogicalKeyboardKey.comma, control: true),
///       onPressed: openSettings,
///     ),
///     const WindowMenuDivider(),
///     ...systemEntries,
///   ],
/// )
/// ```
typedef WindowMenuItemsBuilder =
    List<WindowMenuEntry> Function(
      BuildContext context,
      List<WindowMenuEntry> systemEntries,
    );

/// Builds the icon of a menu entry. [color] already follows the state of the entry
/// (normal / disabled), so draw with it. Any widget works, for example a
/// `WindowCaptionGlyphIcon`.
typedef WindowMenuIconBuilder =
    Widget Function(BuildContext context, Color color);

/// A menu of the title bar. Two menus exist (see `TitleBarContent`):
///
/// * `leadingMenu`: opens when the user clicks (left or right button) the
///   leading widget, usually the app icon.
/// * `barMenu`: opens when the user right-clicks an empty part of the bar.
///
/// Both show the standard Windows entries by default. Use `WindowMenu()` with
/// an [itemsBuilder] to change the entries, or `WindowMenu.disabled()` to turn
/// the menu off.
@immutable
class WindowMenu {
  /// A menu. Without [itemsBuilder] it shows the standard Windows entries.
  const WindowMenu({this.itemsBuilder, this.closeOnDoubleClick = true})
    : isEnabled = true;

  /// No menu: the click does nothing special.
  const WindowMenu.disabled()
    : isEnabled = false,
      closeOnDoubleClick = false,
      itemsBuilder = null;

  final bool isEnabled;

  /// Only used by `leadingMenu`: a double-click on the leading widget closes
  /// the window, exactly like double-clicking the icon of a native window
  /// (the close goes through `onCloseRequested`). Set it to `false` to turn
  /// that off.
  final bool closeOnDoubleClick;

  /// `null` means "the standard Windows entries".
  final WindowMenuItemsBuilder? itemsBuilder;
}

/// One line of a window menu: a [WindowMenuItem] or a [WindowMenuDivider].
sealed class WindowMenuEntry {
  const WindowMenuEntry();
}

/// A clickable line of a window menu.
final class WindowMenuItem extends WindowMenuEntry {
  const WindowMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconBuilder,
    this.shortcut,
    this.activator,
    this.mnemonic,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onPressed;

  /// A small icon shown before the label.
  final IconData? icon;

  /// Any widget as the icon, instead of [icon] (for example one of the Windows
  /// caption glyphs). Takes priority over [icon].
  final WindowMenuIconBuilder? iconBuilder;

  /// A hint shown after the label (for example `Alt+F4`). **Display only**: it
  /// does not bind any key. To make a key work, use [activator]. When both are
  /// given, this text is what is shown.
  final String? shortcut;

  /// The keys that run this entry, from anywhere in the app, even with the menu
  /// closed:
  ///
  /// ```dart
  /// WindowMenuItem(
  ///   label: 'Settings',
  ///   activator: const SingleActivator(LogicalKeyboardKey.comma, control: true),
  ///   onPressed: openSettings,
  /// )
  /// ```
  ///
  /// The text shown after the label (`Ctrl+,`) is made from it, so the hint and
  /// the behavior can never disagree (set [shortcut] to show other text).
  ///
  /// Rules:
  /// * It works while the entry is in the `leadingMenu` or the `barMenu` of the
  ///   bar that is showing, and the entry is enabled.
  /// * It needs `Ctrl`, `Alt` or `Win`, or a key that types nothing (`F5`...): a
  ///   plain letter would fight with typing in text fields.
  /// * A widget that has the focus and wants the key (a text field with
  ///   `Ctrl+C`) gets it first.
  /// * It does nothing while a window menu is open or while a dialog covers the
  ///   window.
  final ShortcutActivator? activator;

  /// The letter that chooses this item from the keyboard while the menu is open
  /// (case-insensitive). Without it, the first letter of [label] is used. When
  /// several items share a letter, pressing it moves through them.
  final String? mnemonic;

  /// A disabled item is shown dimmed and cannot be clicked.
  final bool isEnabled;

  /// What the menu shows after the label: [shortcut] when given, otherwise a
  /// text made from [activator] (`Ctrl+,`), otherwise `null`.
  String? get shortcutLabel {
    final String? text = shortcut;
    if (text != null) return text;
    final ShortcutActivator? keys = activator;
    return keys == null ? null : describeShortcutActivator(keys);
  }
}

/// A thin line that separates groups of entries.
final class WindowMenuDivider extends WindowMenuEntry {
  const WindowMenuDivider();
}
