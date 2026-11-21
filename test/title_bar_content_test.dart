import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/window_frame.dart';

void main() {
  group('TitleBarContent.merge', () {
    test('a field left null keeps the base value', () {
      const TitleBarContent base = TitleBarContent(title: 'Base', spacing: 4);
      final TitleBarContent merged = base.merge(
        const TitleBarContent(backgroundColor: Colors.red),
      );

      expect(merged.title, 'Base');
      expect(merged.spacing, 4);
      expect(merged.backgroundColor, Colors.red);
    });

    test('a field that is set wins over the base value', () {
      const TitleBarContent base = TitleBarContent(title: 'Base');
      final TitleBarContent merged = base.merge(
        const TitleBarContent(title: 'Page'),
      );

      expect(merged.title, 'Page');
    });

    test('an empty title is a value: it hides the title', () {
      const TitleBarContent base = TitleBarContent(title: 'Base');
      final TitleBarContent merged = base.merge(
        const TitleBarContent(title: ''),
      );

      expect(merged.title, '');
    });

    test('an empty list of actions removes the inherited actions', () {
      final TitleBarContent base = TitleBarContent(
        actionBuilders: <WidgetBuilder>[(BuildContext _) => const SizedBox()],
      );
      final TitleBarContent merged = base.merge(
        const TitleBarContent(actionBuilders: <WidgetBuilder>[]),
      );

      expect(merged.actionBuilders, isEmpty);
    });

    test('a disabled menu replaces the inherited menu', () {
      const TitleBarContent base = TitleBarContent(leadingMenu: WindowMenu());
      final TitleBarContent merged = base.merge(
        const TitleBarContent(leadingMenu: WindowMenu.disabled()),
      );

      expect(merged.leadingMenu?.isEnabled, isFalse);
    });

    test('the bar behavior flags are inherited and can be overridden', () {
      const TitleBarContent base = TitleBarContent(isDraggable: false);

      expect(base.merge(const TitleBarContent()).isDraggable, isFalse);
      expect(
        base.merge(const TitleBarContent(isDraggable: true)).isDraggable,
        isTrue,
      );
      expect(
        base
            .merge(const TitleBarContent(doubleClickMaximizes: false))
            .doubleClickMaximizes,
        isFalse,
      );
    });

    test('merging null changes nothing', () {
      const TitleBarContent base = TitleBarContent(title: 'Base');

      expect(base.merge(null).title, 'Base');
    });
  });
}
