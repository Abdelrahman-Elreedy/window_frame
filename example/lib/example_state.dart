// Small pieces of app-wide state shared by the example's files.

import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

/// Light / dark mode, changed from the title bar (see bar_actions.dart).
final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

/// The text direction of the whole app (changed by the right-to-left demo).
final ValueNotifier<TextDirection> appTextDirection =
    ValueNotifier<TextDirection>(TextDirection.ltr);

/// The height of the title bar, changed by the title bar layout demo.
final ValueNotifier<double> titleBarHeightValue = ValueNotifier<double>(36);

/// Which caption-button style is active (changed by the caption buttons demo).
final ValueNotifier<CaptionStyleChoice> captionStyleChoice =
    ValueNotifier<CaptionStyleChoice>(CaptionStyleChoice.windowsDefault);

enum CaptionStyleChoice {
  windowsDefault('Windows default'),
  wideAndThin('Wide buttons, thick glyphs'),
  orangeClose('Orange close button'),
  roundedCloseIcon('Custom close icon'),
  customColors('Custom colors'),
  customGlyphs('Custom glyphs for all four'),
  customSet('A whole set built from WindowCaptionButton'),
  closeOnly('Close button only (showMinimize / showMaximize: false)');

  const CaptionStyleChoice(this.label);

  final String label;
}

/// The caption buttons for a choice. They are given to
/// `WindowFrameScope(captionButtons: ...)` and are the same on every page.
Widget buildCaptionButtons(CaptionStyleChoice choice) {
  switch (choice) {
    case CaptionStyleChoice.windowsDefault:
      return const WindowCaptionButtons();
    case CaptionStyleChoice.wideAndThin:
      return const WindowCaptionButtons(
        style: WindowCaptionButtonsStyle(
          buttonWidth: 60,
          iconSize: 12,
          iconStrokeWidth: 1.6,
        ),
      );
    case CaptionStyleChoice.orangeClose:
      return const WindowCaptionButtons(
        style: WindowCaptionButtonsStyle(
          closeHoverColor: Colors.deepOrange,
          closePressedColor: Colors.orange,
        ),
      );
    case CaptionStyleChoice.roundedCloseIcon:
      return WindowCaptionButtons(
        // Any widget can replace a glyph. [color] already follows the theme,
        // the hover state and the inactive look.
        closeIcon: (BuildContext context, Color color) =>
            Icon(Icons.close_rounded, size: 16, color: color),
      );
    case CaptionStyleChoice.customColors:
      return const WindowCaptionButtons(
        style: WindowCaptionButtonsStyle(
          iconColor: Colors.teal,
          inactiveIconColor: Colors.grey,
          hoverColor: Color(0x3300BFA5),
          pressedColor: Color(0x5500BFA5),
        ),
      );
    case CaptionStyleChoice.customGlyphs:
      return WindowCaptionButtons(
        minimizeIcon: (BuildContext context, Color color) =>
            Icon(Icons.horizontal_rule, size: 16, color: color),
        maximizeIcon: (BuildContext context, Color color) =>
            Icon(Icons.check_box_outline_blank, size: 14, color: color),
        restoreIcon: (BuildContext context, Color color) =>
            Icon(Icons.filter_none, size: 14, color: color),
        closeIcon: (BuildContext context, Color color) =>
            Icon(Icons.close_rounded, size: 16, color: color),
      );
    case CaptionStyleChoice.customSet:
      return const _TrafficLights();
    case CaptionStyleChoice.closeOnly:
      return const WindowCaptionButtons(
        showMinimize: false,
        showMaximize: false,
      );
  }
}

/// A complete set of caption buttons, built from [WindowCaptionButton]: three
/// colored dots. Any widget can be given to `WindowFrameScope.captionButtons`.
class _TrafficLights extends StatelessWidget {
  const _TrafficLights();

  @override
  Widget build(BuildContext context) {
    // The caption buttons stay on the right in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _dot('Minimize', Colors.amber, WindowFrame.minimize),
          _dot('Maximize', Colors.green, WindowFrame.toggleMaximize),
          _dot('Close', Colors.red, WindowFrame.close),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _dot(String label, Color color, VoidCallback onPressed) {
    return WindowCaptionButton(
      label: label,
      width: 32,
      iconColor: color,
      hoverColor: color.withAlpha(40),
      pressedColor: color.withAlpha(80),
      onPressed: onPressed,
      iconBuilder: (BuildContext context, Color iconColor) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
      ),
    );
  }
}
