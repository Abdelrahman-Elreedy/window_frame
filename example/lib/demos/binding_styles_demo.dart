import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

final TitleBarController _extensionController = TitleBarController(
  initialContent: const TitleBarContent(title: 'Style 1: the extension'),
);

final TitleBarController _wrapperController = TitleBarController(
  initialContent: const TitleBarContent(title: 'Style 2: the wrapper widget'),
);

/// Two ways to give a page its own title bar. They do exactly the same thing.
class BindingStylesDemo extends StatelessWidget {
  const BindingStylesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Two ways to attach a bar',
      explanation:
          'A page selects its own title bar in one line. Pick the '
          'style you like: the extension is shorter, the wrapper shows the '
          'controller at the top of the page, where nobody misses it.',
      codeSample: r'''// Style 1: extension (short, good for small pages)
Scaffold(...).withTitleBarController(myController)

// Style 2: wrapper widget (the controller is visible at the top)
TitleBarControllerBinding(
  controller: myController,
  child: Scaffold(...),
)''',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) => const _ExtensionStylePage(),
              ),
            ),
            child: const Text('Open page with style 1'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) => const _WrapperStylePage(),
              ),
            ),
            child: const Text('Open page with style 2'),
          ),
        ],
      ),
    );
  }
}

class _ExtensionStylePage extends StatelessWidget {
  const _ExtensionStylePage();

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      title: 'Style 1',
      explanation:
          'Look at the title bar: it was selected with '
          '.withTitleBarController(...). Go back and the default bar returns.',
      child: SizedBox.shrink(),
    ).withTitleBarController(_extensionController);
  }
}

class _WrapperStylePage extends StatelessWidget {
  const _WrapperStylePage();

  @override
  Widget build(BuildContext context) {
    return TitleBarControllerBinding(
      controller: _wrapperController,
      child: const DemoPage(
        title: 'Style 2',
        explanation:
            'Look at the title bar: it was selected with the '
            'TitleBarControllerBinding widget. Same result as style 1.',
        child: SizedBox.shrink(),
      ),
    );
  }
}
