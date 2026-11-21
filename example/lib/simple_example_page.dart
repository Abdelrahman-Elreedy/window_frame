import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

/// A page controller only says what is DIFFERENT from the default bar. This one
/// says one thing: no action buttons. The logo, the project name and the free
/// area are inherited from the default controller in main.dart.
final TitleBarController _simpleTitleBarController = TitleBarController(
  initialContent: const TitleBarContent(actionBuilders: <WidgetBuilder>[]),
);

/// The smallest page that has its own title bar: one controller, one line.
class SimpleExamplePage extends StatelessWidget {
  const SimpleExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The back arrow comes from the AppBar: this page was pushed.
      appBar: AppBar(title: const Text('Minimal example')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Look at the title bar: it is the default one, without the'),
            Text('three action buttons. Go back and they return.'),
          ],
        ),
      ),
    ).withTitleBarController(_simpleTitleBarController);
  }
}
