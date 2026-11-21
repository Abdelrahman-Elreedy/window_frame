import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

/// WindowDragArea is a public widget: the title bar is built from it, and you can
/// use it anywhere to make a part of YOUR page move the window.
class DragAreaDemo extends StatefulWidget {
  const DragAreaDemo({super.key});

  @override
  State<DragAreaDemo> createState() => _DragAreaDemoState();
}

class _DragAreaDemoState extends State<DragAreaDemo> {
  bool _doubleClickMaximizes = true;
  int _buttonClicks = 0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DemoPage(
      title: 'A drag area in your own page',
      explanation:
          'The box below is a WindowDragArea: drag it and the window '
          'moves, double-click it and the window maximizes (switch that off '
          'below). The button inside it still works: it never moves the window. '
          'The strip at the bottom is a WindowNoDragArea: it draws something and '
          'must not act like empty space.',
      codeSample: r'''WindowDragArea(
  doubleTapToToggleMaximize: true,
  child: MyHeader(),          // buttons inside it keep working
)

WindowNoDragArea(child: MyProgressBar())''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          WindowDragArea(
            doubleTapToToggleMaximize: _doubleClickMaximizes,
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.open_with),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Drag me. I move the whole window.'),
                  ),
                  FilledButton(
                    onPressed: () => setState(() => _buttonClicks++),
                    child: Text('Button: $_buttonClicks'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const WindowNoDragArea(
            child: SizedBox(
              height: 24,
              child: LinearProgressIndicator(value: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Double-click the box maximizes the window'),
            value: _doubleClickMaximizes,
            onChanged: (bool value) =>
                setState(() => _doubleClickMaximizes = value),
          ),
        ],
      ),
    );
  }
}
