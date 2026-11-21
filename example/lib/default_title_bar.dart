import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'bar_actions.dart';

/// The default title bar. It is created ONCE, so it can be changed from
/// anywhere (a page, a Bloc, a service...) with `update` / `setTitle`.
///
/// Pages that do not select another controller show exactly this bar.
final TitleBarController defaultTitleBarController = TitleBarController(
  initialContent: TitleBarContent(
    // Click the logo (left or right button): the window menu opens. Right-click
    // an empty part of the bar for the same menu.
    leadingBuilder: (BuildContext context) => const FlutterLogo(size: 16),
    // The project name from pubspec.yaml. You could leave `title` out: a bar
    // with no title shows the application name anyway. Write your own text
    // to override it, or '' to hide the title.
    title: WindowFrame.applicationTitle,
    contentBuilder: (BuildContext context) => const Center(
      child: Text(
        'Free area: tabs, a menu, anything',
        style: TextStyle(fontSize: 12),
      ),
    ),
    actionBuilders: <WidgetBuilder>[
      (BuildContext context) => const BarActions(),
    ],
  ),
);
