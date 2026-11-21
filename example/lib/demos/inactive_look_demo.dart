import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

final TitleBarController _inactiveLookController = TitleBarController(
  initialContent: const TitleBarContent(title: 'Inactive look'),
);

class InactiveLookDemo extends StatefulWidget {
  const InactiveLookDemo({super.key});

  @override
  State<InactiveLookDemo> createState() => _InactiveLookDemoState();
}

class _InactiveLookDemoState extends State<InactiveLookDemo> {
  bool _dimWhenInactive = true;
  bool _customColors = false;
  bool _slowTransition = false;

  /// replace(): every option is rebuilt from the switches, and an option left
  /// `null` goes back to its default.
  void _apply() {
    _inactiveLookController.replace(
      TitleBarContent(
        title: 'Inactive look',
        dimWhenInactive: _dimWhenInactive,
        inactiveBackgroundColor: _customColors ? const Color(0xFF3E2723) : null,
        inactiveForegroundColor: _customColors ? Colors.orangeAccent : null,
        appearanceTransitionDuration: _slowTransition
            ? const Duration(milliseconds: 800)
            : null,
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
      title: 'The look of an unfocused window',
      explanation:
          'Click on ANOTHER window (for example your editor): the '
          'title bar and the caption buttons fade, like native Windows bars. '
          'Click back and they return. Change the options below, then click '
          'another window to see the difference.',
      codeSample: r'''TitleBarContent(
  dimWhenInactive: true,                       // false = no fading
  inactiveBackgroundColor: Color(0xFF3E2723),  // your own colors
  inactiveForegroundColor: Colors.orangeAccent,
  appearanceTransitionDuration: Duration(milliseconds: 800),
)''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: WindowFrame.isWindowActive,
            builder: (BuildContext context, bool isActive, Widget? _) => Text(
              'Window has the focus: $isActive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text('Fade the bar when unfocused (dimWhenInactive)'),
            value: _dimWhenInactive,
            onChanged: (bool value) => _change(() => _dimWhenInactive = value),
          ),
          SwitchListTile(
            title: const Text('Use my own inactive colors'),
            value: _customColors,
            onChanged: (bool value) => _change(() => _customColors = value),
          ),
          SwitchListTile(
            title: const Text('Slow transition (800 ms)'),
            value: _slowTransition,
            onChanged: (bool value) => _change(() => _slowTransition = value),
          ),
        ],
      ),
    ).withTitleBarController(_inactiveLookController);
  }
}
