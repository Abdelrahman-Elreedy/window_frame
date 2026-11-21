import 'package:flutter/foundation.dart';

import 'package:window_frame/src/presentation/models/title_bar_content.dart';

/// The "writer" of the title bar.
///
/// The app has one default controller (passed to `WindowFrameScope`). Any page
/// can have its own controller: it only describes what differs from the
/// default one, and a page selects it with `.withTitleBarController(...)`.
/// Change the controller at any time (from a page, a Bloc, a service...) and
/// the bar updates.
class TitleBarController extends ChangeNotifier {
  TitleBarController({TitleBarContent initialContent = const TitleBarContent()})
    : _content = initialContent;

  TitleBarContent _content;
  bool _isDisposed = false;

  TitleBarContent get content => _content;

  /// Changes only the fields that [changes] sets; everything else is kept.
  void update(TitleBarContent changes) => replace(_content.merge(changes));

  /// Replaces the whole content (fields left `null` fall back to the default
  /// title bar).
  void replace(TitleBarContent newContent) {
    _content = newContent;
    notifyListeners();
  }

  /// Back to "inherit everything from the default title bar".
  void reset() => replace(const TitleBarContent());

  /// Shortcut for the most common change.
  void setTitle(String title) => update(TitleBarContent(title: title));

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
