// The colors of the title bar for the active and the inactive window, and the
// rules that decide them.

import 'package:flutter/material.dart';

import 'package:window_frame/src/presentation/models/title_bar_content.dart';

/// The colors the title bar must use right now (already decided between the
/// active and the inactive look).
class TitleBarAppearance {
  const TitleBarAppearance({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.transitionDuration,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Duration transitionDuration;
}

/// Decides the title bar colors for the active and the inactive window.
///
/// Default look when the window loses focus (like native Windows bars): the
/// text and icons fade, and the background shifts slightly toward the text
/// color. Every value can be overridden through [TitleBarContent].
class TitleBarAppearanceResolver {
  const TitleBarAppearanceResolver();

  static const Duration defaultTransitionDuration = Duration(milliseconds: 120);

  /// Opacity (0-255) of the text and icons while the window is inactive.
  static const int inactiveForegroundAlpha = 153;

  /// Opacity (0-255) of the text color blended into the inactive background.
  static const int inactiveBackgroundBlendAlpha = 10;

  TitleBarAppearance resolve({
    required TitleBarContent content,
    required ColorScheme colorScheme,
    required bool isWindowActive,
  }) {
    final Color activeBackgroundColor =
        content.backgroundColor ?? colorScheme.surface;
    final Color activeForegroundColor =
        content.foregroundColor ?? colorScheme.onSurface;
    final bool dimWhenInactive = content.dimWhenInactive ?? true;

    final Color inactiveBackgroundColor =
        content.inactiveBackgroundColor ??
        (dimWhenInactive
            ? Color.alphaBlend(
                activeForegroundColor.withAlpha(inactiveBackgroundBlendAlpha),
                activeBackgroundColor,
              )
            : activeBackgroundColor);
    final Color inactiveForegroundColor =
        content.inactiveForegroundColor ??
        (dimWhenInactive
            ? activeForegroundColor.withAlpha(inactiveForegroundAlpha)
            : activeForegroundColor);

    return TitleBarAppearance(
      backgroundColor: isWindowActive
          ? activeBackgroundColor
          : inactiveBackgroundColor,
      foregroundColor: isWindowActive
          ? activeForegroundColor
          : inactiveForegroundColor,
      transitionDuration:
          content.appearanceTransitionDuration ?? defaultTransitionDuration,
    );
  }
}
