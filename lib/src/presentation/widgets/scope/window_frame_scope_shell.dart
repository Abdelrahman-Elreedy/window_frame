// The page that fills the scope's Navigator (the title bar plus the app) and
// the data the scope hands to it.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_title_bar.dart';

/// What the scope hands to its shell page. The Navigator caches the page, so
/// changes travel through a notifier holding a new instance of this class.
class WindowFrameScopeContent {
  const WindowFrameScopeContent({
    required this.child,
    required this.titleBarHeight,
    required this.captionButtons,
  });

  final Widget child;
  final double titleBarHeight;
  final Widget? captionButtons;
}

/// The only page of the scope's Navigator: the title bar on top, the app below.
///
/// The title bar is painted last (above everything) and the app is clipped
/// under it, so nothing inside the app, not even a page transition, can draw
/// over the bar.
class WindowFrameScopeShell extends StatelessWidget {
  const WindowFrameScopeShell({
    super.key,
    required this.contentListenable,
    required this.applicationHeroController,
    required this.onInnerContextAvailable,
  });

  final ValueListenable<WindowFrameScopeContent> contentListenable;

  /// MaterialApp's HeroController, handed back to the app's own Navigator.
  final HeroController? applicationHeroController;

  /// Reports a context that lives inside the scope's Navigator.
  final ValueChanged<BuildContext> onInnerContextAvailable;

  @override
  Widget build(BuildContext context) {
    final WindowFrameServices services = WindowFrameServicesProvider.servicesOf(
      context,
    );

    return ValueListenableBuilder<WindowFrameScopeContent>(
      valueListenable: contentListenable,
      builder:
          (
            BuildContext context,
            WindowFrameScopeContent scopeContent,
            Widget? _,
          ) {
            onInnerContextAvailable(context);
            return ValueListenableBuilder<bool>(
              valueListenable:
                  services.windowFrameViewModel.isCustomFrameActive,
              builder:
                  (BuildContext context, bool isCustomFrameActive, Widget? _) {
                    return _buildLayout(
                      context,
                      scopeContent,
                      isCustomFrameActive,
                    );
                  },
            );
          },
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WindowFrameScopeContent scopeContent,
    bool isCustomFrameActive,
  ) {
    final double titleBarHeight = scopeContent.titleBarHeight;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          top: isCustomFrameActive ? titleBarHeight : 0,
          child: ClipRect(
            child: _buildApplication(
              context,
              scopeContent,
              isCustomFrameActive,
            ),
          ),
        ),
        if (isCustomFrameActive)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: titleBarHeight,
            child: Material(
              type: MaterialType.transparency,
              child: WindowTitleBar(
                captionButtons: scopeContent.captionButtons,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApplication(
    BuildContext context,
    WindowFrameScopeContent scopeContent,
    bool isCustomFrameActive,
  ) {
    Widget application = scopeContent.child;
    final HeroController? heroController = applicationHeroController;
    if (heroController != null) {
      application = HeroControllerScope(
        controller: heroController,
        child: application,
      );
    }

    // The app no longer owns the area under the bar, so tell it its real size.
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return application;
    final double applicationHeight = isCustomFrameActive
        ? mediaQuery.size.height - scopeContent.titleBarHeight
        : mediaQuery.size.height;
    return MediaQuery(
      data: mediaQuery.copyWith(
        size: Size(
          mediaQuery.size.width,
          applicationHeight < 0 ? 0.0 : applicationHeight,
        ),
      ),
      child: application,
    );
  }
}
