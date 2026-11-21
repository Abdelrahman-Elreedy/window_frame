// window_frame/example/lib/main.dart
//
// One app, two examples. The window frame is installed once, in
// MaterialApp.builder, so the custom title bar covers every page:
//
//   ExampleChooserPage  (the home page, uses the default title bar)
//     |-- SimpleExamplePage   a page with its own, almost identical, title bar
//     '-- HomePage           the guided tour: one demo per feature

import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'close_handler.dart';
import 'default_title_bar.dart';
import 'example_state.dart';
import 'example_chooser_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowFrame.init(
    const WindowFrameOptions(
      minimumSize: Size(800, 600),
      startMaximized: true, // set to false to compare the startup look
      // Pixels of the native frame extended into the window. 0 = none (default).
      frameBorderWidth: 0,
    ),
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        themeMode,
        appTextDirection,
        captionStyleChoice,
        titleBarHeightValue,
      ]),
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // The window title in the taskbar comes from windows/runner/main.cpp;
          // this one is used by Flutter itself.
          title: 'window_frame example',
          theme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeMode.value,
          builder: (BuildContext context, Widget? child) => Directionality(
            // Your widgets in the title bar follow the app's direction (try
            // the right-to-left demo); the caption buttons stay on the right.
            textDirection: appTextDirection.value,
            child: WindowFrameScope(
              titleBarController: defaultTitleBarController,
              titleBarHeight: titleBarHeightValue.value,
              // The same caption buttons on every page (see the demo).
              captionButtons: buildCaptionButtons(captionStyleChoice.value),
              onCloseRequested: confirmClose,
              child: child!,
            ),
          ),
          home: const ExampleChooserPage(),
        );
      },
    );
  }
}
