import 'package:flutter/material.dart';

import 'package:window_frame/src/composition/window_frame_composition_root.dart';
import 'package:window_frame/src/presentation/coordinators/window_close_coordinator.dart';
import 'package:window_frame/src/presentation/models/title_bar_content.dart';
import 'package:window_frame/src/presentation/models/window_menu.dart';
import 'package:window_frame/src/presentation/view_models/title_bar_controller.dart';
import 'package:window_frame/src/presentation/view_models/title_bar_view_model.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_view_model.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_scope_shell.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_menu_entries.dart';
import 'package:window_frame/src/presentation/widgets/title_bar/window_menu_shortcuts.dart';

/// Wraps your app: the title bar on top, your app below it.
///
/// Use it in `MaterialApp.builder`. Create the default [TitleBarController]
/// once (a field, a global, a service) so you can change it from anywhere:
///
/// ```dart
/// builder: (context, child) => WindowFrameScope(
///   titleBarController: defaultTitleBarController,
///   onCloseRequested: (context) async => true,
///   child: child!,
/// )
/// ```
///
/// How it works: the scope hosts the whole app inside its own root
/// `Navigator`. That is what lets widgets in the bar use `Tooltip`,
/// `PopupMenuButton`, `DropdownButton`, `showDialog`... like widgets in a page.
///
/// Things to know:
/// * `showDialog` & co. from your pages use the root Navigator by default, so
///   they land in this scope's Navigator: the dialog and its dim barrier cover
///   the whole window, including the title bar.
/// * Do not call `Navigator.of(context, rootNavigator: true).push(page)` to
///   open full pages: that Navigator only hosts your app.
/// * Providers declared below `MaterialApp` (inside a page) are not visible to
///   the title bar; providers above `MaterialApp` are.
class WindowFrameScope extends StatefulWidget {
  const WindowFrameScope({
    super.key,
    required this.child,
    this.titleBarController,
    this.title,
    this.titleBarHeight = 32,
    this.captionButtons,
    this.onCloseRequested,
  });

  final Widget child;

  /// The default title bar. Create it once and keep it alive; pages can change
  /// the bar with their own controllers. When `null`, the scope creates a
  /// private one showing [title].
  final TitleBarController? titleBarController;

  /// Title of the private default controller (used only when
  /// [titleBarController] is `null`). When this is `null` too, the
  /// application name (`WindowFrame.applicationTitle`) is shown.
  final String? title;

  /// Height of the bar. The single place where the height is defined.
  final double titleBarHeight;

  /// Caption buttons used on every page (e.g. a styled `WindowCaptionButtons`).
  final Widget? captionButtons;

  /// Runs before the window closes. See [WindowCloseRequestHandler].
  final WindowCloseRequestHandler? onCloseRequested;

  @override
  State<WindowFrameScope> createState() => _WindowFrameScopeState();
}

class _WindowFrameScopeState extends State<WindowFrameScope> {
  late final TitleBarControllerRegistry _registry;
  late final TitleBarViewModel _titleBarViewModel;
  late final WindowFrameServices _services;
  late final WindowCloseCoordinator _closeCoordinator;
  late final AppLifecycleListener _lifecycleListener;
  late final ValueNotifier<WindowFrameScopeContent> _scopeContent;

  TitleBarController? _privateDefaultController;
  BuildContext? _contextInsideNavigator;

  @override
  void initState() {
    super.initState();
    _registry = TitleBarControllerRegistry();
    _titleBarViewModel = TitleBarViewModel(
      defaultController: _resolveDefaultController(),
      registry: _registry,
    );
    _services = WindowFrameServices(
      windowFrameViewModel: WindowFrameCompositionRoot.windowFrameViewModel,
      titleBarViewModel: _titleBarViewModel,
      titleBarControllerRegistry: _registry,
      windowMenuViewModel: WindowMenuViewModel(
        WindowFrameCompositionRoot.windowFrameViewModel,
      ),
    );
    _closeCoordinator = WindowCloseCoordinator(
      requestHandlerProvider: () => widget.onCloseRequested,
      contextProvider: () => _contextInsideNavigator,
    );
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _closeCoordinator.handleExitRequest,
    );
    _scopeContent = ValueNotifier<WindowFrameScopeContent>(
      _createScopeContent(),
    );
  }

  @override
  void didUpdateWidget(WindowFrameScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _titleBarViewModel.defaultController = _resolveDefaultController();
    // The Navigator caches the shell page, so changes travel through this
    // notifier.
    _scopeContent.value = _createScopeContent();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _scopeContent.dispose();
    _titleBarViewModel.dispose();
    _registry.dispose();
    _privateDefaultController?.dispose();
    super.dispose();
  }

  TitleBarController _resolveDefaultController() {
    return widget.titleBarController ??
        (_privateDefaultController ??= TitleBarController(
          initialContent: TitleBarContent(title: widget.title),
        ));
  }

  WindowFrameScopeContent _createScopeContent() {
    return WindowFrameScopeContent(
      child: widget.child,
      titleBarHeight: widget.titleBarHeight,
      captionButtons: widget.captionButtons,
    );
  }

  /// The entries of the two menus of the bar that is showing. Only the ones that
  /// have their own `itemsBuilder` can own a shortcut (the standard entries
  /// have none).
  List<WindowMenuEntry> _collectShortcutEntries() {
    final BuildContext? context = _contextInsideNavigator;
    if (context == null || !context.mounted) return const <WindowMenuEntry>[];
    final TitleBarContent content = _titleBarViewModel.resolvedContent;
    final List<WindowMenuEntry> entries = <WindowMenuEntry>[];
    for (final WindowMenu? menu in <WindowMenu?>[
      content.leadingMenu,
      content.barMenu,
    ]) {
      if (menu == null || !menu.isEnabled || menu.itemsBuilder == null) {
        continue;
      }
      entries.addAll(
        buildWindowMenuEntries(context, menu, _services.windowMenuViewModel),
      );
    }
    return entries;
  }

  /// Shortcuts stay silent while a window menu is open and while a dialog (or
  /// any other route above the window page) covers the window.
  bool _areShortcutsBlocked() {
    final BuildContext? context = _contextInsideNavigator;
    if (context == null || !context.mounted) return true;
    if (_services.windowMenuViewModel.isMenuOpen) return true;
    final ModalRoute<Object?>? route = ModalRoute.of<Object?>(context);
    return route != null && !route.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    if (!WindowFrameCompositionRoot.isPlatformSupported) return widget.child;

    // MaterialApp's HeroController may be attached to ONE Navigator only: this
    // scope's Navigator gets none, and the app's own Navigator gets it back.
    final HeroController? applicationHeroController =
        HeroControllerScope.maybeOf(context);

    return WindowFrameServicesProvider(
      services: _services,
      // Above the Navigator, so a key pressed anywhere in the app bubbles up
      // to the shortcuts of the menu entries.
      child: WindowMenuShortcuts(
        entriesProvider: _collectShortcutEntries,
        isBlocked: _areShortcutsBlocked,
        child: HeroControllerScope.none(
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) =>
                PageRouteBuilder<void>(
                  settings: settings,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder:
                      (
                        BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                      ) => WindowFrameScopeShell(
                        contentListenable: _scopeContent,
                        applicationHeroController: applicationHeroController,
                        onInnerContextAvailable: (BuildContext innerContext) {
                          _contextInsideNavigator = innerContext;
                        },
                      ),
                ),
          ),
        ),
      ),
    );
  }
}
