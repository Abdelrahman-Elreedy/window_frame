// How a page selects its own title bar: the wrapper widget and the one-line
// extension that uses it.

import 'package:flutter/widgets.dart';

import 'package:window_frame/src/presentation/view_models/title_bar_controller.dart';
import 'package:window_frame/src/presentation/view_models/title_bar_view_model.dart';
import 'package:window_frame/src/presentation/widgets/scope/window_frame_services.dart';

/// Binds a [TitleBarController] to the life of a page: while the page is the
/// current page, the title bar follows [controller]; when the page is covered
/// or popped, the previous controller (or the default bar) comes back.
///
/// Usually written as `page.withTitleBarController(controller)`.
class TitleBarControllerBinding extends StatefulWidget {
  const TitleBarControllerBinding({
    super.key,
    required this.controller,
    required this.child,
  });

  final TitleBarController controller;
  final Widget child;

  @override
  State<TitleBarControllerBinding> createState() =>
      _TitleBarControllerBindingState();
}

class _TitleBarControllerBindingState extends State<TitleBarControllerBinding> {
  TitleBarControllerRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TitleBarControllerRegistry? currentRegistry =
        WindowFrameServicesProvider.maybeServicesOf(
          context,
        )?.titleBarControllerRegistry;
    if (!identical(currentRegistry, _registry)) {
      _deactivateAfterFrame(_registry);
      _registry = currentRegistry;
    }
    _synchronizeActivation();
  }

  @override
  void didUpdateWidget(TitleBarControllerBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeActivation();
  }

  @override
  void dispose() {
    _deactivateAfterFrame(_registry);
    super.dispose();
  }

  /// Activates the controller when this page is the current one, deactivates
  /// it otherwise. Done after the frame: notifying the title bar while the
  /// tree is building would throw "setState() called during build".
  void _synchronizeActivation() {
    final TitleBarControllerRegistry? registry = _registry;
    if (registry == null) return;

    final ModalRoute<Object?>? route = ModalRoute.of<Object?>(context);
    final bool isCurrentPage = route == null || route.isCurrent;
    final TitleBarController controller = widget.controller;

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (isCurrentPage && mounted) {
        registry.activate(owner: this, controller: controller);
      } else {
        registry.deactivate(this);
      }
    });
  }

  void _deactivateAfterFrame(TitleBarControllerRegistry? registry) {
    if (registry == null) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => registry.deactivate(this),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One-line way to give a page its own title bar:
///
/// ```dart
/// Scaffold(...).withTitleBarController(invoiceTitleBarController)
/// ```
extension TitleBarControllerBindingExtension on Widget {
  Widget withTitleBarController(TitleBarController controller) {
    return TitleBarControllerBinding(controller: controller, child: this);
  }
}
