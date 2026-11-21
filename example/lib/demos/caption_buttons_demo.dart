import 'package:flutter/material.dart';

import '../example_state.dart';
import 'demo_page.dart';

class CaptionButtonsDemo extends StatelessWidget {
  const CaptionButtonsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Restyle the caption buttons',
      explanation:
          'The minimize / maximize / close buttons are drawn by the '
          'plugin and follow the theme and the inactive look. You can change '
          'their size, colors and glyphs, replace each glyph with any widget, '
          'or replace the whole set with buttons of your own (made from '
          'WindowCaptionButton). They are set once on WindowFrameScope and '
          'stay the same on every page. Choose a style and look at the top '
          'right corner.',
      codeSample: r'''WindowFrameScope(
  captionButtons: WindowCaptionButtons(
    style: WindowCaptionButtonsStyle(buttonWidth: 60, iconStrokeWidth: 1.6),
    closeIcon: (context, color) =>
        Icon(Icons.close_rounded, size: 16, color: color),
  ),
  child: child!,
)''',
      child: ValueListenableBuilder<CaptionStyleChoice>(
        valueListenable: captionStyleChoice,
        builder: (BuildContext context, CaptionStyleChoice current, Widget? _) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CaptionStyleChoice choice in CaptionStyleChoice.values)
                ChoiceChip(
                  label: Text(choice.label),
                  selected: choice == current,
                  onSelected: (bool _) => captionStyleChoice.value = choice,
                ),
            ],
          );
        },
      ),
    );
  }
}
