import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import '../example_state.dart';
import 'demo_page.dart';

final TitleBarController _rtlController = TitleBarController(
  initialContent: TitleBarContent(
    leadingBuilder: (BuildContext context) => const Icon(Icons.translate),
    title: 'صفحة عربية',
    contentBuilder: (BuildContext context) => const Center(
      child: Text(
        'هذه المساحة تتبع اتجاه التطبيق',
        style: TextStyle(fontSize: 12),
      ),
    ),
    actionBuilders: <WidgetBuilder>[
      (BuildContext context) => IconButton(
        tooltip: 'بحث',
        icon: const Icon(Icons.search),
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40),
        onPressed: () {},
      ),
    ],
  ),
);

class RtlDemo extends StatelessWidget {
  const RtlDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Right-to-left (Arabic)',
      explanation:
          'Turn the switch on: the whole app becomes right-to-left. '
          'Your widgets in the bar follow the app direction, while the bar '
          'itself and the caption buttons stay on the right, exactly like in '
          'every Windows app. Names in any language also work as the title. '
          'Turn it off again when you are done.',
      child: ValueListenableBuilder<TextDirection>(
        valueListenable: appTextDirection,
        builder: (BuildContext context, TextDirection direction, Widget? _) =>
            SwitchListTile(
              title: const Text('Right-to-left app'),
              value: direction == TextDirection.rtl,
              onChanged: (bool isRtl) => appTextDirection.value = isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
      ),
    ).withTitleBarController(_rtlController);
  }
}
