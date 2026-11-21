import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import '../example_state.dart';
import 'demo_page.dart';

final TitleBarController _layoutController = TitleBarController(
  initialContent: const TitleBarContent(title: 'Title bar layout'),
);

/// The look of the bar itself: the height (set on WindowFrameScope) and the title
/// style, the padding and the spacing (set in TitleBarContent).
class TitleLayoutDemo extends StatefulWidget {
  const TitleLayoutDemo({super.key});

  @override
  State<TitleLayoutDemo> createState() => _TitleLayoutDemoState();
}

class _TitleLayoutDemoState extends State<TitleLayoutDemo> {
  double _fontSize = 12;
  double _leftPadding = 12;
  double _spacing = 8;
  bool _bold = false;
  bool _draggable = true;
  bool _doubleClickMaximizes = true;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  void _apply() {
    _layoutController.replace(
      TitleBarContent(
        leadingBuilder: (BuildContext context) => const FlutterLogo(size: 16),
        title: 'Title bar layout',
        titleStyle: TextStyle(
          fontSize: _fontSize,
          fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
        ),
        padding: EdgeInsets.only(left: _leftPadding),
        spacing: _spacing,
        isDraggable: _draggable,
        doubleClickMaximizes: _doubleClickMaximizes,
      ),
    );
  }

  void _change(VoidCallback change) {
    setState(change);
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Height, title style, padding and spacing',
      explanation:
          'The height of the whole bar is set once on '
          'WindowFrameScope(titleBarHeight). The title style, the padding '
          'around the drag area and the spacing between the logo and the title '
          'are fields of TitleBarContent, so a page can change them, and so are '
          'isDraggable and doubleClickMaximizes. Move the sliders and watch the '
          'bar.',
      codeSample: r'''WindowFrameScope(titleBarHeight: 44, ...)

TitleBarContent(
  titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  padding: EdgeInsets.only(left: 24),   // space around the drag area
  spacing: 16,                          // between the logo and the title
)''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<double>(
            valueListenable: titleBarHeightValue,
            builder: (BuildContext context, double height, Widget? _) =>
                _SliderRow(
                  label: 'Bar height (WindowFrameScope): ${height.round()}',
                  value: height,
                  min: 28,
                  max: 56,
                  onChanged: (double value) =>
                      titleBarHeightValue.value = value,
                ),
          ),
          _SliderRow(
            label: 'Title font size: ${_fontSize.round()}',
            value: _fontSize,
            min: 10,
            max: 22,
            onChanged: (double value) => _change(() => _fontSize = value),
          ),
          _SliderRow(
            label: 'Left padding: ${_leftPadding.round()}',
            value: _leftPadding,
            min: 0,
            max: 48,
            onChanged: (double value) => _change(() => _leftPadding = value),
          ),
          _SliderRow(
            label: 'Spacing logo / title: ${_spacing.round()}',
            value: _spacing,
            min: 0,
            max: 32,
            onChanged: (double value) => _change(() => _spacing = value),
          ),
          SwitchListTile(
            title: const Text('Bold title'),
            value: _bold,
            onChanged: (bool value) => _change(() => _bold = value),
          ),
          SwitchListTile(
            title: const Text('The bar moves the window (isDraggable)'),
            value: _draggable,
            onChanged: (bool value) => _change(() => _draggable = value),
          ),
          SwitchListTile(
            title: const Text('Double-click maximizes (doubleClickMaximizes)'),
            value: _doubleClickMaximizes,
            onChanged: (bool value) =>
                _change(() => _doubleClickMaximizes = value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () {
                titleBarHeightValue.value = 36;
                _change(() {
                  _fontSize = 12;
                  _leftPadding = 12;
                  _spacing = 8;
                  _bold = false;
                  _draggable = true;
                  _doubleClickMaximizes = true;
                });
              },
              child: const Text('Back to the defaults'),
            ),
          ),
        ],
      ),
    ).withTitleBarController(_layoutController);
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 280, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
