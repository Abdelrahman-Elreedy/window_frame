/// Custom window frame for Flutter Windows desktop apps.
///
/// ```dart
/// import 'package:window_frame/window_frame.dart';
/// ```
library;

export 'src/domain/entities/window_entities.dart' show WindowFrameOptions;
export 'src/presentation/coordinators/window_close_coordinator.dart'
    show WindowCloseRequestHandler;
export 'src/presentation/facade/window_frame.dart' show WindowFrame;
export 'src/presentation/models/title_bar_content.dart' show TitleBarContent;
export 'src/presentation/models/window_menu.dart'
    show
        WindowMenu,
        WindowMenuDivider,
        WindowMenuEntry,
        WindowMenuIconBuilder,
        WindowMenuItem,
        WindowMenuItemsBuilder;
export 'src/presentation/view_models/title_bar_controller.dart'
    show TitleBarController;
export 'src/presentation/widgets/caption_buttons/window_caption_button.dart'
    show WindowCaptionButton, WindowCaptionIconBuilder;
export 'src/presentation/widgets/caption_buttons/window_caption_buttons.dart'
    show WindowCaptionButtons, WindowCaptionButtonsStyle;
export 'src/presentation/widgets/caption_buttons/window_caption_glyph_painter.dart'
    show WindowCaptionGlyph, WindowCaptionGlyphIcon, WindowCaptionGlyphPainter;
export 'src/presentation/widgets/scope/window_frame_scope.dart'
    show WindowFrameScope;
export 'src/presentation/widgets/title_bar/title_bar_controller_binding.dart'
    show TitleBarControllerBinding, TitleBarControllerBindingExtension;
export 'src/presentation/widgets/title_bar/window_drag_area.dart'
    show WindowDragArea, WindowNoDragArea;
