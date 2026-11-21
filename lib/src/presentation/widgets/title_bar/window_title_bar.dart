import 'dart:async';

import 'package:flutter/material.dart';

import 'package:window_frame/src/presentation/models/title_bar_content.dart';
import 'package:window_frame/src/presentation/models/window_menu.dart';
import 'package:window_frame/src/presentation/resolvers/title_bar_appearance_resolver.dart';
import 'package:window_frame/src/presentation/widgets/caption_buttons/window_caption_buttons.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_drag_area.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_menu_presenter.dart';

/// The title bar view. It draws what the title bar view model resolves:
///
/// ```
/// [leading] [title] [content ............] [actions] [caption buttons]
/// ```
///
/// Everything left of the actions is a drag area. The bar fades while the
/// window is inactive. It fills the height it is given by `WindowFrameScope`.
class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    this.captionButtons,
    this.appearanceResolver = const TitleBarAppearanceResolver(),
  });

  /// Replaces the default caption buttons (the same on every page).
  final Widget? captionButtons;
  final TitleBarAppearanceResolver appearanceResolver;

  static const EdgeInsets _defaultPadding = EdgeInsets.only(left: 12);
  static const double _defaultSpacing = 8;
  static const double _defaultIconSize = 16;

  @override
  Widget build(BuildContext context) {
    final WindowFrameServices services = WindowFrameServicesProvider.servicesOf(
      context,
    );

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.titleBarViewModel,
        services.windowFrameViewModel.isWindowActive,
      ]),
      builder: (BuildContext context, Widget? _) =>
          _buildBar(context, services),
    );
  }

  Widget _buildBar(BuildContext context, WindowFrameServices services) {
    final TitleBarContent content = services.titleBarViewModel.resolvedContent;
    final TitleBarAppearance appearance = appearanceResolver.resolve(
      content: content,
      colorScheme: Theme.of(context).colorScheme,
      isWindowActive: services.windowFrameViewModel.isWindowActive.value,
    );
    // Read before the bar forces left-to-right: the user's widgets keep the
    // direction of the app (e.g. right-to-left for Arabic).
    final TextDirection applicationTextDirection = Directionality.of(context);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: appearance.foregroundColor),
      duration: appearance.transitionDuration,
      builder: (BuildContext context, Color? animatedColor, Widget? _) {
        final Color foregroundColor =
            animatedColor ?? appearance.foregroundColor;
        return AnimatedContainer(
          duration: appearance.transitionDuration,
          color: appearance.backgroundColor,
          child: Material(
            type: MaterialType.transparency,
            child: IconTheme(
              data: IconThemeData(
                color: foregroundColor,
                size: _defaultIconSize,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foregroundColor),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: _buildLayout(
                    context: context,
                    content: content,
                    foregroundColor: foregroundColor,
                    applicationTextDirection: applicationTextDirection,
                    applicationTitle:
                        services.windowFrameViewModel.applicationTitle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayout({
    required BuildContext context,
    required TitleBarContent content,
    required Color foregroundColor,
    required TextDirection applicationTextDirection,
    required String applicationTitle,
  }) {
    Widget inApplicationDirection(Widget widget) {
      return Directionality(
        textDirection: applicationTextDirection,
        child: widget,
      );
    }

    final Widget? titleWidget = _buildTitle(
      content,
      foregroundColor,
      applicationTitle,
    );
    final List<WidgetBuilder> actionBuilders =
        content.actionBuilders ?? const <WidgetBuilder>[];
    // Both menus show the standard Windows entries unless the app says more.
    final WindowMenu leadingMenu = content.leadingMenu ?? const WindowMenu();
    final WindowMenu barMenu = content.barMenu ?? const WindowMenu();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: WindowDragArea(
            isDraggable: content.isDraggable ?? true,
            doubleTapToToggleMaximize: content.doubleClickMaximizes ?? true,
            onContextMenuRequested: barMenu.isEnabled
                ? (Offset position) => unawaited(
                    showWindowMenu(
                      context: context,
                      globalPosition: position,
                      menu: barMenu,
                    ),
                  )
                : null,
            child: Padding(
              padding: content.padding ?? _defaultPadding,
              child: Row(
                children: <Widget>[
                  if (content.leadingBuilder != null) ...<Widget>[
                    inApplicationDirection(
                      _buildLeading(content.leadingBuilder!, leadingMenu),
                    ),
                    SizedBox(width: content.spacing ?? _defaultSpacing),
                  ],
                  if (titleWidget != null)
                    Flexible(child: inApplicationDirection(titleWidget)),
                  Expanded(
                    child: content.contentBuilder == null
                        ? const SizedBox.shrink()
                        : inApplicationDirection(
                            Builder(builder: content.contentBuilder!),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final WidgetBuilder actionBuilder in actionBuilders)
          inApplicationDirection(Builder(builder: actionBuilder)),
        captionButtons ?? const WindowCaptionButtons(),
      ],
    );
  }

  Widget _buildLeading(WidgetBuilder leadingBuilder, WindowMenu leadingMenu) {
    final Widget leading = Builder(builder: leadingBuilder);
    if (!leadingMenu.isEnabled) return leading;
    return WindowMenuTrigger(menu: leadingMenu, child: leading);
  }

  Widget? _buildTitle(
    TitleBarContent content,
    Color foregroundColor,
    String applicationTitle,
  ) {
    if (content.titleBuilder != null) {
      return Builder(builder: content.titleBuilder!);
    }
    // No title anywhere in the controllers: show the application name. An
    // empty title ('') hides the title on purpose.
    final String title = content.title ?? applicationTitle;
    if (title.isEmpty) return null;
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: foregroundColor,
      ).merge(content.titleStyle),
    );
  }
}
