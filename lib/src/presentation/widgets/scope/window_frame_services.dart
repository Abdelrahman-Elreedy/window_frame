import 'package:flutter/widgets.dart';

import 'package:window_frame/src/composition/window_frame_composition_root.dart';
import 'package:window_frame/src/presentation/view_models/title_bar_view_model.dart';
import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_view_model.dart';

/// The view models a `WindowFrameScope` shares with the widgets below it.
class WindowFrameServices {
  const WindowFrameServices({
    required this.windowFrameViewModel,
    required this.titleBarViewModel,
    required this.titleBarControllerRegistry,
    required this.windowMenuViewModel,
  });

  final WindowFrameViewModel windowFrameViewModel;
  final TitleBarViewModel titleBarViewModel;
  final TitleBarControllerRegistry titleBarControllerRegistry;
  final WindowMenuViewModel windowMenuViewModel;
}

/// Hands the [WindowFrameServices] down the widget tree.
class WindowFrameServicesProvider extends InheritedWidget {
  const WindowFrameServicesProvider({
    super.key,
    required this.services,
    required super.child,
  });

  final WindowFrameServices services;

  /// The services, or `null` when there is no `WindowFrameScope` above.
  static WindowFrameServices? maybeServicesOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<WindowFrameServicesProvider>()
        ?.services;
  }

  /// The services of the `WindowFrameScope` above [context].
  static WindowFrameServices servicesOf(BuildContext context) {
    final WindowFrameServices? services = maybeServicesOf(context);
    assert(
      services != null,
      'No WindowFrameScope found above this widget. '
      'Put WindowFrameScope in MaterialApp.builder.',
    );
    return services!;
  }

  /// The window view model: from the scope when there is one, otherwise the
  /// shared one (so caption buttons also work outside a scope).
  static WindowFrameViewModel windowFrameViewModelOf(BuildContext context) {
    return maybeServicesOf(context)?.windowFrameViewModel ??
        WindowFrameCompositionRoot.windowFrameViewModel;
  }

  @override
  bool updateShouldNotify(WindowFrameServicesProvider oldWidget) =>
      services != oldWidget.services;
}
