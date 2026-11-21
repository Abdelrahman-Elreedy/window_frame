// Which controller the title bar follows: the registry remembers the page
// controllers, the view model merges the default and the current page's one.

import 'package:flutter/foundation.dart';

import 'package:window_frame/src/presentation/models/title_bar_content.dart';
import 'package:window_frame/src/presentation/view_models/title_bar_controller.dart';

/// Remembers which pages selected which controller. The most recently
/// activated controller is the one the title bar uses ("the top page wins").
class TitleBarControllerRegistry extends ChangeNotifier {
  final List<_ControllerActivation> _activations = <_ControllerActivation>[];
  bool _isDisposed = false;

  /// The controller the bar must follow, or `null` for "default bar only".
  TitleBarController? get activeController =>
      _activations.isEmpty ? null : _activations.last.controller;

  void activate({
    required Object owner,
    required TitleBarController controller,
  }) {
    _activations.removeWhere(
      (_ControllerActivation activation) => identical(activation.owner, owner),
    );
    _activations.add(_ControllerActivation(owner, controller));
    notifyListeners();
  }

  void deactivate(Object owner) {
    final int countBefore = _activations.length;
    _activations.removeWhere(
      (_ControllerActivation activation) => identical(activation.owner, owner),
    );
    if (_activations.length != countBefore) {
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class _ControllerActivation {
  const _ControllerActivation(this.owner, this.controller);

  final Object owner;
  final TitleBarController controller;
}

/// Combines the default controller with the controller of the current page
/// into the one [resolvedContent] the title bar draws.
///
/// It notifies its listeners whenever the default controller, the current
/// page's controller, or the choice of the current page changes.
class TitleBarViewModel extends ChangeNotifier {
  TitleBarViewModel({
    required TitleBarController defaultController,
    required TitleBarControllerRegistry registry,
  }) : _defaultController = defaultController,
       _registry = registry {
    _defaultController.addListener(_notifyContentChanged);
    _registry.addListener(_followActiveController);
    _followActiveController();
  }

  TitleBarController _defaultController;
  final TitleBarControllerRegistry _registry;
  TitleBarController? _followedPageController;

  TitleBarContent get resolvedContent =>
      _defaultController.content.merge(_followedPageController?.content);

  set defaultController(TitleBarController newController) {
    if (identical(newController, _defaultController)) return;
    _defaultController.removeListener(_notifyContentChanged);
    _defaultController = newController;
    _defaultController.addListener(_notifyContentChanged);
    _notifyContentChanged();
  }

  @override
  void dispose() {
    _defaultController.removeListener(_notifyContentChanged);
    _registry.removeListener(_followActiveController);
    _followedPageController?.removeListener(_notifyContentChanged);
    super.dispose();
  }

  void _followActiveController() {
    final TitleBarController? activeController = _registry.activeController;
    if (!identical(activeController, _followedPageController)) {
      _followedPageController?.removeListener(_notifyContentChanged);
      _followedPageController = activeController;
      _followedPageController?.addListener(_notifyContentChanged);
    }
    _notifyContentChanged();
  }

  void _notifyContentChanged() => notifyListeners();
}
