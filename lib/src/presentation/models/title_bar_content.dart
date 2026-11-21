import 'package:flutter/widgets.dart';
import 'package:window_frame/src/presentation/models/window_menu.dart';

/// Describes what the title bar shows. Every field is optional: a field left
/// `null` means "inherit it", so a controller only has to say what differs
/// from the default title bar.
///
/// Widgets are given as builders (`WidgetBuilder`), not as ready widgets: the
/// bar calls them with a context that lives INSIDE the window's Navigator, so
/// `showDialog`, `Tooltip`, `PopupMenuButton`... work in any slot.
@immutable
class TitleBarContent {
  const TitleBarContent({
    this.leadingBuilder,
    this.title,
    this.titleBuilder,
    this.titleStyle,
    this.contentBuilder,
    this.actionBuilders,
    this.backgroundColor,
    this.foregroundColor,
    this.inactiveBackgroundColor,
    this.inactiveForegroundColor,
    this.dimWhenInactive,
    this.appearanceTransitionDuration,
    this.padding,
    this.spacing,
    this.leadingMenu,
    this.barMenu,
    this.isDraggable,
    this.doubleClickMaximizes,
  });

  /// Always on the left (e.g. the app icon).
  final WidgetBuilder? leadingBuilder;

  /// The title as text. Ignored when [titleBuilder] is set.
  ///
  /// * `null` (the default): the application name is shown. It comes from
  ///   `WindowFrame.applicationTitle`, i.e. the project name in `pubspec.yaml`.
  /// * a text: that text is shown.
  /// * `''` (empty): no title is shown.
  final String? title;
  final WidgetBuilder? titleBuilder;
  final TextStyle? titleStyle;

  /// Fills all the free space between the title and the actions.
  final WidgetBuilder? contentBuilder;

  /// Placed right before the caption buttons. An empty list removes the
  /// inherited actions.
  final List<WidgetBuilder>? actionBuilders;

  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Colors used while the window is not the active window.
  /// Default: derived from the active colors.
  final Color? inactiveBackgroundColor;
  final Color? inactiveForegroundColor;

  /// Dim the bar while the window is inactive (default: true).
  final bool? dimWhenInactive;

  /// Duration of the color change between active and inactive.
  final Duration? appearanceTransitionDuration;

  /// Space around the draggable area (left side only by default).
  final EdgeInsets? padding;

  /// Space between the leading widget and the title.
  final double? spacing;

  /// The menu that opens when the user clicks the leading widget (left or
  /// right button), like the icon menu of a native window. `null` means the
  /// standard Windows menu; use `WindowMenu.disabled()` for no menu.
  final WindowMenu? leadingMenu;

  /// The menu that opens when the user right-clicks an empty part of the bar.
  /// `null` means the standard Windows menu; use `WindowMenu.disabled()` for
  /// no menu.
  final WindowMenu? barMenu;

  /// Whether dragging an empty part of the bar moves the window. `null` means
  /// yes. Use `false` for a window that must stay where it is.
  final bool? isDraggable;

  /// Whether a double-click on an empty part of the bar maximizes / restores the
  /// window. `null` means yes.
  final bool? doubleClickMaximizes;

  /// This content, with every field that [overlay] sets replaced by it.
  TitleBarContent merge(TitleBarContent? overlay) {
    if (overlay == null) return this;
    return TitleBarContent(
      leadingBuilder: overlay.leadingBuilder ?? leadingBuilder,
      title: overlay.title ?? title,
      titleBuilder: overlay.titleBuilder ?? titleBuilder,
      titleStyle: overlay.titleStyle ?? titleStyle,
      contentBuilder: overlay.contentBuilder ?? contentBuilder,
      actionBuilders: overlay.actionBuilders ?? actionBuilders,
      backgroundColor: overlay.backgroundColor ?? backgroundColor,
      foregroundColor: overlay.foregroundColor ?? foregroundColor,
      inactiveBackgroundColor:
          overlay.inactiveBackgroundColor ?? inactiveBackgroundColor,
      inactiveForegroundColor:
          overlay.inactiveForegroundColor ?? inactiveForegroundColor,
      dimWhenInactive: overlay.dimWhenInactive ?? dimWhenInactive,
      appearanceTransitionDuration:
          overlay.appearanceTransitionDuration ?? appearanceTransitionDuration,
      padding: overlay.padding ?? padding,
      spacing: overlay.spacing ?? spacing,
      leadingMenu: overlay.leadingMenu ?? leadingMenu,
      barMenu: overlay.barMenu ?? barMenu,
      isDraggable: overlay.isDraggable ?? isDraggable,
      doubleClickMaximizes:
          overlay.doubleClickMaximizes ?? doubleClickMaximizes,
    );
  }
}
