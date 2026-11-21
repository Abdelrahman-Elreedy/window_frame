// The three standard caption buttons, their style and the rules that decide
// their colors.

import 'package:flutter/material.dart';

import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';
import 'package:window_frame/src/presentation/widgets/caption_buttons/window_caption_button.dart';
import 'package:window_frame/src/presentation/widgets/caption_buttons/window_caption_glyph_painter.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';

/// Sizes and colors of the caption buttons.
///
/// Every color left `null` is derived from the title bar's text color, so
/// light, dark and inactive-window looks work without any setup.
class WindowCaptionButtonsStyle {
  const WindowCaptionButtonsStyle({
    this.buttonWidth = 46,
    this.iconSize = 10,
    this.iconStrokeWidth = 1,
    this.iconColor,
    this.inactiveIconColor,
    this.hoverColor,
    this.pressedColor,
    this.closeHoverColor = const Color(0xFFE81123),
    this.closePressedColor = const Color(0xFFF1707A),
    this.closeHoverIconColor = Colors.white,
  });

  final double buttonWidth;

  /// Size of the built-in glyphs (logical pixels, 10 = Windows size).
  final double iconSize;
  final double iconStrokeWidth;

  /// Icon color. Default: the title bar's text color.
  final Color? iconColor;

  /// Icon color while the window is inactive. Default: [iconColor] faded.
  final Color? inactiveIconColor;

  /// Background while hovering / pressing. Default: icon color at 10% / 20%.
  final Color? hoverColor;
  final Color? pressedColor;

  final Color closeHoverColor;
  final Color closePressedColor;
  final Color closeHoverIconColor;
}

/// The three colors one caption button needs right now.
class CaptionButtonsColors {
  const CaptionButtonsColors({
    required this.icon,
    required this.hover,
    required this.pressed,
  });

  final Color icon;
  final Color hover;
  final Color pressed;
}

/// Decides the caption button colors from the style, the title bar's text
/// color and whether the window is active.
class CaptionButtonsColorResolver {
  const CaptionButtonsColorResolver();

  static const int hoverAlpha = 26;
  static const int pressedAlpha = 51;
  static const int inactiveIconAlpha = 153;

  CaptionButtonsColors resolve({
    required WindowCaptionButtonsStyle style,
    required Color titleBarForegroundColor,
    required bool isWindowActive,
  }) {
    final Color icon = _resolveIconColor(
      style: style,
      titleBarForegroundColor: titleBarForegroundColor,
      isWindowActive: isWindowActive,
    );
    return CaptionButtonsColors(
      icon: icon,
      hover: style.hoverColor ?? icon.withAlpha(hoverAlpha),
      pressed: style.pressedColor ?? icon.withAlpha(pressedAlpha),
    );
  }

  Color _resolveIconColor({
    required WindowCaptionButtonsStyle style,
    required Color titleBarForegroundColor,
    required bool isWindowActive,
  }) {
    final Color? explicitIconColor = style.iconColor;
    if (explicitIconColor == null) {
      // The title bar already fades its text color while the window is
      // inactive, so following it is enough.
      return titleBarForegroundColor;
    }
    if (isWindowActive) return explicitIconColor;
    return style.inactiveIconColor ??
        explicitIconColor.withAlpha(inactiveIconAlpha);
  }
}

/// The three standard buttons: minimize, maximize/restore, close.
///
/// The glyphs are drawn with `CustomPaint` (Windows style) and each one can be
/// replaced through the `*Icon` parameters. Colors follow the title bar's
/// text color, so dark mode and the inactive-window look work by themselves.
///
/// Needs a bounded height (it stretches to the bar's height).
class WindowCaptionButtons extends StatelessWidget {
  const WindowCaptionButtons({
    super.key,
    this.style = const WindowCaptionButtonsStyle(),
    this.minimizeIcon,
    this.maximizeIcon,
    this.restoreIcon,
    this.closeIcon,
    this.showMinimize = true,
    this.showMaximize = true,
    this.showClose = true,
    this.colorResolver = const CaptionButtonsColorResolver(),
  });

  final WindowCaptionButtonsStyle style;
  final WindowCaptionIconBuilder? minimizeIcon;
  final WindowCaptionIconBuilder? maximizeIcon;
  final WindowCaptionIconBuilder? restoreIcon;
  final WindowCaptionIconBuilder? closeIcon;

  /// Show the minimize / maximize-restore / close button. Hide the ones the
  /// window should not offer (a dialog-like window shows only the close button).
  final bool showMinimize;
  final bool showMaximize;
  final bool showClose;

  final CaptionButtonsColorResolver colorResolver;

  @override
  Widget build(BuildContext context) {
    final WindowFrameViewModel windowViewModel =
        WindowFrameServicesProvider.windowFrameViewModelOf(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        windowViewModel.isMaximized,
        windowViewModel.isWindowActive,
      ]),
      builder: (BuildContext context, Widget? _) {
        final CaptionButtonsColors colors = colorResolver.resolve(
          style: style,
          titleBarForegroundColor: _titleBarForegroundColor(context),
          isWindowActive: windowViewModel.isWindowActive.value,
        );
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showMinimize) _buildMinimizeButton(colors, windowViewModel),
              if (showMaximize)
                _buildMaximizeOrRestoreButton(colors, windowViewModel),
              if (showClose) _buildCloseButton(colors, windowViewModel),
            ],
          ),
        );
      },
    );
  }

  Color _titleBarForegroundColor(BuildContext context) {
    return IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
  }

  Widget _buildMinimizeButton(
    CaptionButtonsColors colors,
    WindowFrameViewModel windowViewModel,
  ) {
    return WindowCaptionButton(
      label: 'Minimize',
      width: style.buttonWidth,
      iconColor: colors.icon,
      hoverColor: colors.hover,
      pressedColor: colors.pressed,
      iconBuilder: minimizeIcon ?? _glyphBuilder(WindowCaptionGlyph.minimize),
      onPressed: windowViewModel.minimize,
    );
  }

  Widget _buildMaximizeOrRestoreButton(
    CaptionButtonsColors colors,
    WindowFrameViewModel windowViewModel,
  ) {
    final bool isMaximized = windowViewModel.isMaximized.value;
    return WindowCaptionButton(
      label: isMaximized ? 'Restore' : 'Maximize',
      width: style.buttonWidth,
      iconColor: colors.icon,
      hoverColor: colors.hover,
      pressedColor: colors.pressed,
      iconBuilder: isMaximized
          ? (restoreIcon ?? _glyphBuilder(WindowCaptionGlyph.restore))
          : (maximizeIcon ?? _glyphBuilder(WindowCaptionGlyph.maximize)),
      onPressed: windowViewModel.toggleMaximize,
    );
  }

  Widget _buildCloseButton(
    CaptionButtonsColors colors,
    WindowFrameViewModel windowViewModel,
  ) {
    return WindowCaptionButton(
      label: 'Close',
      width: style.buttonWidth,
      iconColor: colors.icon,
      hoverColor: style.closeHoverColor,
      pressedColor: style.closePressedColor,
      hoverIconColor: style.closeHoverIconColor,
      iconBuilder: closeIcon ?? _glyphBuilder(WindowCaptionGlyph.close),
      onPressed: windowViewModel.requestClose,
    );
  }

  WindowCaptionIconBuilder _glyphBuilder(WindowCaptionGlyph glyph) {
    return (BuildContext context, Color color) => WindowCaptionGlyphIcon(
      glyph: glyph,
      size: style.iconSize,
      color: color,
      strokeWidth: style.iconStrokeWidth,
    );
  }
}
