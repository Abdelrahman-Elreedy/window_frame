import 'package:flutter/widgets.dart';

import 'package:window_frame/src/presentation/models/window_menu.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_view_model.dart';
import 'package:window_frame/src/presentation/widgets/caption_buttons/window_caption_glyph_painter.dart';

/// The entries to show for [menu], right now.
///
/// It builds the standard Windows entries (Restore, Minimize, Maximize, Close)
/// from the window state of [viewModel] and lets the app's [WindowMenu] change
/// them. The icons are widgets, which is why this lives with the views and not in
/// the view model.
List<WindowMenuEntry> buildWindowMenuEntries(
  BuildContext context,
  WindowMenu menu,
  WindowMenuViewModel viewModel,
) {
  final List<WindowMenuEntry> systemEntries = _buildSystemEntries(viewModel);
  final WindowMenuItemsBuilder? itemsBuilder = menu.itemsBuilder;
  if (itemsBuilder == null) return systemEntries;
  return itemsBuilder(context, systemEntries);
}

List<WindowMenuEntry> _buildSystemEntries(WindowMenuViewModel viewModel) {
  final bool isMaximized = viewModel.isMaximized;
  return <WindowMenuEntry>[
    WindowMenuItem(
      label: 'Restore',
      mnemonic: 'R',
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(glyph: WindowCaptionGlyph.restore, color: color),
      isEnabled: isMaximized,
      onPressed: viewModel.restore,
    ),
    WindowMenuItem(
      label: 'Minimize',
      mnemonic: 'N',
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(
            glyph: WindowCaptionGlyph.minimize,
            color: color,
          ),
      onPressed: viewModel.minimize,
    ),
    WindowMenuItem(
      label: 'Maximize',
      mnemonic: 'X',
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(
            glyph: WindowCaptionGlyph.maximize,
            color: color,
          ),
      isEnabled: !isMaximized,
      onPressed: viewModel.maximize,
    ),
    const WindowMenuDivider(),
    WindowMenuItem(
      label: 'Close',
      mnemonic: 'C',
      iconBuilder: (BuildContext context, Color color) =>
          WindowCaptionGlyphIcon(glyph: WindowCaptionGlyph.close, color: color),
      shortcut: 'Alt+F4',
      onPressed: viewModel.requestClose,
    ),
  ];
}
