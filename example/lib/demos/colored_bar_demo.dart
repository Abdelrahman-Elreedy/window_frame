import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

/// This page only says what DIFFERS from the default bar: a title and colors.
/// The logo, the free area and the actions are inherited.
final TitleBarController _coloredController = TitleBarController(
  initialContent: const TitleBarContent(
    title: 'Colored bar',
    backgroundColor: Color(0xFF00796B),
    foregroundColor: Colors.white,
  ),
);

const List<Color> _palette = <Color>[
  Color(0xFF00796B),
  Color(0xFF1565C0),
  Color(0xFFAD1457),
  Color(0xFFEF6C00),
  Color(0xFF37474F),
];

class ColoredBarDemo extends StatelessWidget {
  const ColoredBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'A page with its own colors',
      explanation:
          'This page sets only a title and two colors. The logo, the '
          'free area and the actions are INHERITED from the default bar, '
          'because every field a controller leaves empty means "use the '
          'default one". Tap a color to change the bar live.',
      codeSample: r'''TitleBarController(
  initialContent: TitleBarContent(
    title: 'Colored bar',
    backgroundColor: Color(0xFF00796B),
    foregroundColor: Colors.white,
  ),
)''',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final Color color in _palette)
            GestureDetector(
              onTap: () => _coloredController.update(
                TitleBarContent(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
              child: CircleAvatar(backgroundColor: color, radius: 18),
            ),
          OutlinedButton(
            // replace(): everything left empty goes back to the default bar.
            onPressed: () => _coloredController.replace(
              const TitleBarContent(title: 'Colored bar'),
            ),
            child: const Text('Back to the theme colors'),
          ),
          OutlinedButton(
            // reset(): the controller inherits EVERYTHING again, title included.
            onPressed: _coloredController.reset,
            child: const Text('reset() (inherit everything)'),
          ),
        ],
      ),
    ).withTitleBarController(_coloredController);
  }
}
