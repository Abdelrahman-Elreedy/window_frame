import 'package:flutter/material.dart';

/// Builds the icon of one caption button. [color] already reflects the theme
/// (light / dark), the window state and the hover state, so draw with it. Any
/// widget works: an `Icon`, an SVG, your own `CustomPaint`...
typedef WindowCaptionIconBuilder =
    Widget Function(BuildContext context, Color color);

/// One caption button with hover and pressed states and an accessibility
/// label. Use it to build your own set of buttons.
class WindowCaptionButton extends StatefulWidget {
  const WindowCaptionButton({
    super.key,
    required this.label,
    required this.iconBuilder,
    required this.iconColor,
    required this.hoverColor,
    required this.pressedColor,
    required this.onPressed,
    this.width = 46,
    this.hoverIconColor,
  });

  /// Read by screen readers.
  final String label;
  final WindowCaptionIconBuilder iconBuilder;
  final Color iconColor;
  final Color hoverColor;
  final Color pressedColor;

  /// Icon color while hovering or pressing (e.g. white on the red close button).
  final Color? hoverIconColor;
  final double width;
  final VoidCallback onPressed;

  @override
  State<WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<WindowCaptionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = _isHovering || _isPressed;
    final Color backgroundColor = _isPressed
        ? widget.pressedColor
        : (_isHovering ? widget.hoverColor : Colors.transparent);
    final Color iconColor = isHighlighted && widget.hoverIconColor != null
        ? widget.hoverIconColor!
        : widget.iconColor;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: Container(
            width: widget.width,
            color: backgroundColor,
            alignment: Alignment.center,
            child: widget.iconBuilder(context, iconColor),
          ),
        ),
      ),
    );
  }
}
