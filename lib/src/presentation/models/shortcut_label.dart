import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart'
    show CharacterActivator, ShortcutActivator, SingleActivator;

/// The text a menu shows for [activator], in the Windows style (`Ctrl+,`,
/// `Ctrl+Shift+S`, `F5`), or `null` when the activator has no simple label
/// (for example a `LogicalKeySet`).
String? describeShortcutActivator(ShortcutActivator activator) {
  if (activator is SingleActivator) {
    final String? key = _describeKey(activator.trigger);
    if (key == null) return null;
    return <String>[
      if (activator.control) 'Ctrl',
      if (activator.alt) 'Alt',
      if (activator.shift) 'Shift',
      if (activator.meta) 'Win',
      key,
    ].join('+');
  }
  if (activator is CharacterActivator) {
    return <String>[
      if (activator.control) 'Ctrl',
      if (activator.alt) 'Alt',
      if (activator.meta) 'Win',
      activator.character.toUpperCase(),
    ].join('+');
  }
  return null;
}

final Map<LogicalKeyboardKey, String> _specialKeys =
    <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.enter: 'Enter',
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.delete: 'Del',
      LogicalKeyboardKey.insert: 'Ins',
      LogicalKeyboardKey.home: 'Home',
      LogicalKeyboardKey.end: 'End',
      LogicalKeyboardKey.pageUp: 'PgUp',
      LogicalKeyboardKey.pageDown: 'PgDn',
      LogicalKeyboardKey.arrowLeft: 'Left',
      LogicalKeyboardKey.arrowRight: 'Right',
      LogicalKeyboardKey.arrowUp: 'Up',
      LogicalKeyboardKey.arrowDown: 'Down',
    };

String? _describeKey(LogicalKeyboardKey key) {
  final String? special = _specialKeys[key];
  if (special != null) return special;
  final String label = key.keyLabel;
  if (label.trim().isEmpty) return key.debugName;
  return label.length == 1 ? label.toUpperCase() : label;
}
