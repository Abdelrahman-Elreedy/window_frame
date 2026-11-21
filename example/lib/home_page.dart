import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'default_title_bar.dart';
import 'demos/binding_styles_demo.dart';
import 'demos/caption_buttons_demo.dart';
import 'demos/colored_bar_demo.dart';
import 'demos/counter_demo.dart';
import 'demos/drag_area_demo.dart';
import 'demos/inactive_look_demo.dart';
import 'demos/live_status_demo.dart';
import 'demos/rtl_demo.dart';
import 'demos/search_demo.dart';
import 'demos/tabs_demo.dart';
import 'demos/title_layout_demo.dart';
import 'demos/window_menu_demo.dart';

class _Demo {
  const _Demo(this.icon, this.title, this.subtitle, this.builder);

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final List<_Demo> _demos = <_Demo>[
  _Demo(
    Icons.link,
    'Two ways to attach a bar',
    '.withTitleBarController(...) and TitleBarControllerBinding',
    (BuildContext _) => const BindingStylesDemo(),
  ),
  _Demo(
    Icons.palette,
    'A page with its own colors',
    'A controller only says what differs; the rest is inherited',
    (BuildContext _) => const ColoredBarDemo(),
  ),
  _Demo(
    Icons.tab,
    'Tabs in the title bar',
    'Any widget in the free area, and a hidden title',
    (BuildContext _) => const TabsDemo(),
  ),
  _Demo(
    Icons.add_circle_outline,
    'A counter in the title bar',
    'The page calls setTitle; the bar follows its controller',
    (BuildContext _) => const CounterDemo(),
  ),
  _Demo(
    Icons.search,
    'A search box and a breadcrumb',
    'titleBuilder and a real TextField in the bar',
    (BuildContext _) => const SearchDemo(),
  ),
  _Demo(
    Icons.sync,
    'Update the bar from a service',
    'A plain Dart class drives the title and a progress bar',
    (BuildContext _) => const LiveStatusDemo(),
  ),
  _Demo(
    Icons.filter_none,
    'The look of an unfocused window',
    'Fade, colors and speed when another window has the focus',
    (BuildContext _) => const InactiveLookDemo(),
  ),
  _Demo(
    Icons.web_asset,
    'Restyle the caption buttons',
    'Size, colors and custom glyphs',
    (BuildContext _) => const CaptionButtonsDemo(),
  ),
  _Demo(
    Icons.height,
    'Height, title style, padding and spacing',
    'titleBarHeight on the scope; titleStyle, padding, spacing in the content',
    (BuildContext _) => const TitleLayoutDemo(),
  ),
  _Demo(
    Icons.open_with,
    'A drag area in your own page',
    'WindowDragArea and WindowNoDragArea outside the title bar',
    (BuildContext _) => const DragAreaDemo(),
  ),
  _Demo(
    Icons.menu_open,
    'Window menus and the drag area',
    'Icon menu, right-click menu, and a no-drag zone',
    (BuildContext _) => const WindowMenuDemo(),
  ),
  _Demo(
    Icons.translate,
    'Right-to-left (Arabic)',
    'Your widgets follow the app direction',
    (BuildContext _) => const RtlDemo(),
  ),
];

/// The home page uses the DEFAULT title bar (it selects no controller).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('window_frame: guided tour')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const _WindowStateCard(),
          const SizedBox(height: 16),
          const _WindowCommandsCard(),
          const SizedBox(height: 24),
          Text('Demos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final _Demo demo in _demos)
            Card(
              child: ListTile(
                leading: Icon(demo.icon),
                title: Text(demo.title),
                subtitle: Text(demo.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: demo.builder)),
              ),
            ),
        ],
      ),
    );
  }
}

/// What the plugin reports about the window, live.
class _WindowStateCard extends StatelessWidget {
  const _WindowStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Window state (live)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Application name: ${WindowFrame.applicationTitle}'),
            Text('Windows (isSupported): ${WindowFrame.isSupported}'),
            _StateLine(
              label: 'Custom frame active',
              value: WindowFrame.frameActive,
            ),
            _StateLine(label: 'Maximized', value: WindowFrame.isMaximized),
            _StateLine(
              label: 'Window has the focus',
              value: WindowFrame.isWindowActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _StateLine extends StatelessWidget {
  const _StateLine({required this.label, required this.value});

  final String label;
  final ValueListenable<bool> value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (BuildContext context, bool current, Widget? _) =>
          Text('$label: $current'),
    );
  }
}

/// Window commands, and changing the DEFAULT bar from anywhere.
class _WindowCommandsCard extends StatelessWidget {
  const _WindowCommandsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Window commands',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: WindowFrame.minimize,
                  child: const Text('Minimize'),
                ),
                OutlinedButton(
                  onPressed: WindowFrame.maximize,
                  child: const Text('Maximize'),
                ),
                OutlinedButton(
                  onPressed: WindowFrame.toggleMaximize,
                  child: const Text('Toggle maximize'),
                ),
                OutlinedButton(
                  onPressed: WindowFrame.restore,
                  child: const Text('Restore'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      WindowFrame.setMinimumSize(const Size(1000, 700)),
                  child: const Text('Min size 1000x700'),
                ),
                OutlinedButton(
                  onPressed: () => WindowFrame.close(),
                  child: const Text('Close (asks first)'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: restore the window first (min size does not apply while maximized).',
              style: TextStyle(fontSize: 12),
            ),
            const Divider(height: 32),
            Text(
              'Change the default title bar from anywhere',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => defaultTitleBarController.setTitle(
                    'Renamed at ${TimeOfDay.now().format(context)}',
                  ),
                  child: const Text('Rename the title'),
                ),
                FilledButton.tonal(
                  onPressed: () => defaultTitleBarController.setTitle(
                    WindowFrame.applicationTitle,
                  ),
                  child: const Text('Back to the application name'),
                ),
                FilledButton.tonal(
                  onPressed: () => defaultTitleBarController.setTitle(''),
                  child: const Text('Hide the title'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
