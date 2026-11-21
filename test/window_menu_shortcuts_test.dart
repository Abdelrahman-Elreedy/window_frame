import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_menu_shortcuts.dart';
import 'package:window_frame/window_frame.dart';

const SingleActivator _ctrlComma = SingleActivator(
  LogicalKeyboardKey.comma,
  control: true,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<WindowMenuEntry> Function() entries,
  bool Function()? isBlocked,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: WindowMenuShortcuts(
        entriesProvider: entries,
        isBlocked: isBlocked,
        child: const Focus(autofocus: true, child: SizedBox()),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pressCtrlComma(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  group('WindowMenuShortcuts', () {
    testWidgets('runs the entry whose keys were pressed', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await _pump(
        tester,
        entries: () => <WindowMenuEntry>[
          WindowMenuItem(
            label: 'Settings',
            activator: _ctrlComma,
            onPressed: () => calls++,
          ),
        ],
      );

      await _pressCtrlComma(tester);

      expect(calls, 1);
    });

    testWidgets('does not run a disabled entry', (WidgetTester tester) async {
      int calls = 0;
      await _pump(
        tester,
        entries: () => <WindowMenuEntry>[
          WindowMenuItem(
            label: 'Settings',
            activator: _ctrlComma,
            isEnabled: false,
            onPressed: () => calls++,
          ),
        ],
      );

      await _pressCtrlComma(tester);

      expect(calls, 0);
    });

    testWidgets('does nothing while it is blocked', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      bool blocked = true;
      await _pump(
        tester,
        isBlocked: () => blocked,
        entries: () => <WindowMenuEntry>[
          WindowMenuItem(
            label: 'Settings',
            activator: _ctrlComma,
            onPressed: () => calls++,
          ),
        ],
      );

      await _pressCtrlComma(tester);
      expect(calls, 0);

      blocked = false;
      await _pressCtrlComma(tester);
      expect(calls, 1);
    });

    testWidgets('judges an entry by its state at the moment of the key', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      bool enabled = false;
      await _pump(
        tester,
        entries: () => <WindowMenuEntry>[
          WindowMenuItem(
            label: 'Save',
            activator: _ctrlComma,
            isEnabled: enabled,
            onPressed: () => calls++,
          ),
        ],
      );

      await _pressCtrlComma(tester);
      expect(calls, 0);

      enabled = true;
      await _pressCtrlComma(tester);
      expect(calls, 1);
    });

    testWidgets('a key that is not a shortcut falls through', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await _pump(
        tester,
        entries: () => <WindowMenuEntry>[
          WindowMenuItem(
            label: 'Settings',
            activator: _ctrlComma,
            onPressed: () => calls++,
          ),
        ],
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(calls, 0);
    });

    testWidgets('a plain typed character never builds the entries', (
      WidgetTester tester,
    ) async {
      int built = 0;
      await _pump(
        tester,
        entries: () {
          built++;
          return const <WindowMenuEntry>[];
        },
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);

      expect(built, 0);
    });
  });
}
