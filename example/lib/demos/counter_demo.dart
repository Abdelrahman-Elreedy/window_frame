import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

final TitleBarController _counterController = TitleBarController(
  initialContent: const TitleBarContent(title: 'Counter: 0'),
);

/// The title bar follows the controller: change the controller, the bar updates.
class CounterDemo extends StatefulWidget {
  const CounterDemo({super.key});

  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _counterController.setTitle('Counter: 0'); // start from zero on every visit
  }

  void _increment() {
    setState(() => _count++);
    // The title bar follows the controller: change it, the bar updates.
    _counterController.setTitle('Counter: $_count');
  }

  @override
  Widget build(BuildContext context) {
    // This page uses the wrapper widget; the other demos use the extension.
    return TitleBarControllerBinding(
      controller: _counterController,
      child: DemoPage(
        title: 'A counter in the title bar',
        explanation:
            'Press the button: the number in the title bar changes. '
            'The page only calls setTitle on its controller; it never touches '
            'the title bar widget.',
        codeSample: r'''void _increment() {
  setState(() => _count++);
  counterTitleBarController.setTitle('Counter: $_count');
}''',
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _increment,
            child: Text('Pressed $_count times (watch the title bar)'),
          ),
        ),
      ),
    );
  }
}
