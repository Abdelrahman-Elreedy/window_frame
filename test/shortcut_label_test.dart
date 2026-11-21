import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/src/presentation/models/shortcut_label.dart';
import 'package:window_frame/window_frame.dart';

void main() {
  group('describeShortcutActivator', () {
    test('writes the modifiers in the Windows order, then the key', () {
      expect(
        describeShortcutActivator(
          const SingleActivator(LogicalKeyboardKey.comma, control: true),
        ),
        'Ctrl+,',
      );
      expect(
        describeShortcutActivator(
          const SingleActivator(
            LogicalKeyboardKey.keyS,
            control: true,
            shift: true,
          ),
        ),
        'Ctrl+Shift+S',
      );
      expect(
        describeShortcutActivator(
          const SingleActivator(
            LogicalKeyboardKey.keyK,
            control: true,
            alt: true,
            shift: true,
            meta: true,
          ),
        ),
        'Ctrl+Alt+Shift+Win+K',
      );
    });

    test('names the keys that have no printable label', () {
      expect(
        describeShortcutActivator(
          const SingleActivator(LogicalKeyboardKey.escape),
        ),
        'Esc',
      );
      expect(
        describeShortcutActivator(
          const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
        ),
        'Alt+Left',
      );
      expect(
        describeShortcutActivator(
          const SingleActivator(LogicalKeyboardKey.delete),
        ),
        'Del',
      );
    });

    test('keeps the label of a function key', () {
      expect(
        describeShortcutActivator(const SingleActivator(LogicalKeyboardKey.f5)),
        'F5',
      );
    });

    test('describes a character activator', () {
      expect(
        describeShortcutActivator(const CharacterActivator('?', control: true)),
        'Ctrl+?',
      );
    });

    test('has no label for an activator it cannot describe', () {
      expect(
        describeShortcutActivator(
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
        ),
        isNull,
      );
    });
  });

  group('WindowMenuItem.shortcutLabel', () {
    test('is made from the activator', () {
      final WindowMenuItem item = WindowMenuItem(
        label: 'Settings',
        onPressed: () {},
        activator: const SingleActivator(
          LogicalKeyboardKey.comma,
          control: true,
        ),
      );

      expect(item.shortcutLabel, 'Ctrl+,');
    });

    test('the text given as shortcut wins over the activator', () {
      final WindowMenuItem item = WindowMenuItem(
        label: 'Settings',
        onPressed: () {},
        shortcut: 'Ctrl + comma',
        activator: const SingleActivator(
          LogicalKeyboardKey.comma,
          control: true,
        ),
      );

      expect(item.shortcutLabel, 'Ctrl + comma');
    });

    test('is the plain hint when there is no activator', () {
      final WindowMenuItem item = WindowMenuItem(
        label: 'Close',
        onPressed: () {},
        shortcut: 'Alt+F4',
      );

      expect(item.shortcutLabel, 'Alt+F4');
    });

    test('is null with neither', () {
      final WindowMenuItem item = WindowMenuItem(
        label: 'Close',
        onPressed: () {},
      );

      expect(item.shortcutLabel, isNull);
    });
  });
}
