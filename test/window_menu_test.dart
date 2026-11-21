import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/window_frame.dart';

void main() {
  group('WindowMenu', () {
    test('is enabled and asks for the standard entries by default', () {
      const WindowMenu menu = WindowMenu();

      expect(menu.isEnabled, isTrue);
      expect(menu.itemsBuilder, isNull);
      expect(menu.closeOnDoubleClick, isTrue);
    });

    test('a disabled menu has no entries and no double-click close', () {
      const WindowMenu menu = WindowMenu.disabled();

      expect(menu.isEnabled, isFalse);
      expect(menu.itemsBuilder, isNull);
      expect(menu.closeOnDoubleClick, isFalse);
    });

    test('closing on double-click can be turned off', () {
      const WindowMenu menu = WindowMenu(closeOnDoubleClick: false);

      expect(menu.isEnabled, isTrue);
      expect(menu.closeOnDoubleClick, isFalse);
    });
  });

  group('WindowMenuItem', () {
    test('is enabled by default and keeps what it was given', () {
      void onPressed() {}
      final WindowMenuItem item = WindowMenuItem(
        label: 'Settings',
        onPressed: onPressed,
        icon: Icons.settings,
        shortcut: 'Ctrl+,',
        mnemonic: 'S',
      );

      expect(item.isEnabled, isTrue);
      expect(item.label, 'Settings');
      expect(item.icon, Icons.settings);
      expect(item.shortcut, 'Ctrl+,');
      expect(item.mnemonic, 'S');
    });
  });
}
