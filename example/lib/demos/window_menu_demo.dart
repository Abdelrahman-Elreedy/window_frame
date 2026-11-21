import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

final ValueNotifier<int> _chipClicks = ValueNotifier<int>(0);

/// The bar of this page. It is built by a function because the two menus can be
/// switched on and off by the switches of the page.
final TitleBarController _menuController = TitleBarController(
  initialContent: _buildContent(
    leadingMenuEnabled: true,
    barMenuEnabled: true,
    closeOnDoubleClick: true,
  ),
);

TitleBarContent _buildContent({
  required bool leadingMenuEnabled,
  required bool barMenuEnabled,
  required bool closeOnDoubleClick,
}) {
  return TitleBarContent(
    title: 'Window menus',
    leadingBuilder: (BuildContext context) => const Icon(Icons.apps),
    contentBuilder: (BuildContext context) => const Center(
      // A custom widget that handles the mouse by itself: wrapped in a
      // WindowNoDragArea, pressing it never moves the window and a
      // double-click on it never maximizes it.
      child: WindowNoDragArea(child: _ClickCounterChip()),
    ),
    // Click the icon (left or right button): your entries, then the standard ones.
    leadingMenu: leadingMenuEnabled
        ? WindowMenu(
            itemsBuilder: _leadingEntries,
            // false: double-clicking the icon no longer closes the window.
            closeOnDoubleClick: closeOnDoubleClick,
          )
        : const WindowMenu.disabled(),
    // Right-click an empty part of the bar: a menu made only of your entries.
    barMenu: barMenuEnabled
        ? const WindowMenu(itemsBuilder: _barEntries)
        : const WindowMenu.disabled(),
  );
}

List<WindowMenuEntry> _leadingEntries(
  BuildContext context,
  List<WindowMenuEntry> systemEntries,
) {
  return <WindowMenuEntry>[
    WindowMenuItem(
      label: 'About this app',
      icon: Icons.info_outline,
      onPressed: () => _showMessage(context, 'About this app'),
    ),
    WindowMenuItem(
      label: 'Settings',
      icon: Icons.settings,
      // These keys run the entry from anywhere in the app, even with the menu
      // closed. The text shown at the right of the entry ("Ctrl+,") is made
      // from them.
      activator: const SingleActivator(LogicalKeyboardKey.comma, control: true),
      // The letter that runs this entry while the menu is open (underlined).
      mnemonic: 'S',
      onPressed: () => _showMessage(context, 'Settings'),
    ),
    // A disabled entry is dimmed and cannot be run.
    WindowMenuItem(
      label: 'Export (disabled)',
      icon: Icons.upload_file,
      isEnabled: false,
      onPressed: () {},
    ),
    const WindowMenuDivider(),
    ...systemEntries, // Restore, Minimize, Maximize, Close
  ];
}

List<WindowMenuEntry> _barEntries(
  BuildContext context,
  List<WindowMenuEntry> systemEntries,
) {
  // [systemEntries] is ignored: this menu is entirely yours (here, in Arabic).
  return <WindowMenuEntry>[
    WindowMenuItem(
      label: 'تصغير',
      // The Windows caption glyphs are public: use them as any icon.
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(
            glyph: WindowCaptionGlyph.minimize,
            color: color,
          ),
      onPressed: WindowFrame.minimize,
    ),
    WindowMenuItem(
      label: 'إغلاق',
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(glyph: WindowCaptionGlyph.close, color: color),
      onPressed: WindowFrame.close,
    ),
  ];
}

void _showMessage(BuildContext context, String text) {
  showDialog<void>(
    context: context,
    builder: (BuildContext _) => AlertDialog(title: Text(text)),
  );
}

class _ClickCounterChip extends StatelessWidget {
  const _ClickCounterChip();

  @override
  Widget build(BuildContext context) {
    final Color border = Theme.of(context).colorScheme.outline;
    return Listener(
      onPointerDown: (PointerDownEvent _) => _chipClicks.value++,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: _chipClicks,
          builder: (BuildContext context, int clicks, Widget? _) => Text(
            'No-drag zone: $clicks clicks',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class WindowMenuDemo extends StatefulWidget {
  const WindowMenuDemo({super.key});

  @override
  State<WindowMenuDemo> createState() => _WindowMenuDemoState();
}

class _WindowMenuDemoState extends State<WindowMenuDemo> {
  bool _leadingMenuEnabled = true;
  bool _closeOnDoubleClick = true;
  bool _barMenuEnabled = true;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  void _apply() {
    _menuController.replace(
      _buildContent(
        leadingMenuEnabled: _leadingMenuEnabled,
        closeOnDoubleClick: _closeOnDoubleClick,
        barMenuEnabled: _barMenuEnabled,
      ),
    );
  }

  void _change(VoidCallback change) {
    setState(change);
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Window menus and the drag area',
      explanation:
          'Click the icon at the left of the title bar with the left '
          'or the right mouse button: a menu opens, like the icon menu of a '
          'native window. Double-click the icon: the window closes, also like a '
          'native one. Right-click an empty part of the bar for a second '
          'menu; with a menu open, right-click somewhere else: the new menu '
          'opens at once. Both menus show the standard Windows entries by '
          'default and both can be changed or turned off. Also try: '
          'double-click the empty bar (it maximizes), double-click the '
          'no-drag zone (nothing happens) and drag from it (the window stays). '
          'Press Ctrl+, anywhere, even while typing in the box below: the '
          'Settings entry of the icon menu runs.',
      codeSample: r'''TitleBarContent(
  leadingMenu: WindowMenu(
    itemsBuilder: (context, systemEntries) => [
      WindowMenuItem(
        label: 'Settings',
        // Runs from anywhere; the "Ctrl+," hint is made from it.
        activator: SingleActivator(LogicalKeyboardKey.comma, control: true),
        onPressed: openSettings,
      ),
      const WindowMenuDivider(),
      ...systemEntries, // Restore, Minimize, Maximize, Close
    ],
  ),
  barMenu: WindowMenu.disabled(), // no right-click menu
)
// leadingMenu: WindowMenu(closeOnDoubleClick: false) keeps the icon menu
// but turns off the double-click-to-close.''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            title: const Text('Icon menu (left or right click on the icon)'),
            value: _leadingMenuEnabled,
            onChanged: (bool value) =>
                _change(() => _leadingMenuEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Double-click the icon closes the window'),
            value: _closeOnDoubleClick,
            onChanged: (bool value) =>
                _change(() => _closeOnDoubleClick = value),
          ),
          SwitchListTile(
            title: const Text('Bar menu (right click on an empty part)'),
            value: _barMenuEnabled,
            onChanged: (bool value) => _change(() => _barMenuEnabled = value),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Type here, then press Ctrl+,',
              ),
            ),
          ),
        ],
      ),
    ).withTitleBarController(_menuController);
  }
}
