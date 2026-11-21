// The four pictures drawn on the caption buttons, the painter that draws them and
// a widget to use them anywhere (the caption buttons, the window menu, your own UI).

import 'package:flutter/widgets.dart';

/// The four pictures drawn on the caption buttons.
enum WindowCaptionGlyph { minimize, maximize, restore, close }

/// Draws the Windows caption glyphs on a 10x10 grid, scaled to the box size.
class WindowCaptionGlyphPainter extends CustomPainter {
  const WindowCaptionGlyphPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final WindowCaptionGlyph glyph;
  final Color color;
  final double strokeWidth;

  static const double _gridSize = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final double unit = size.width / _gridSize;

    switch (glyph) {
      case WindowCaptionGlyph.minimize:
        _paintMinimize(canvas, paint, unit);
      case WindowCaptionGlyph.maximize:
        _paintMaximize(canvas, paint, unit);
      case WindowCaptionGlyph.restore:
        _paintRestore(canvas, paint, unit);
      case WindowCaptionGlyph.close:
        _paintClose(canvas, paint, unit);
    }
  }

  void _paintMinimize(Canvas canvas, Paint paint, double unit) {
    canvas.drawLine(
      Offset(0, 5.5 * unit),
      Offset(10 * unit, 5.5 * unit),
      paint,
    );
  }

  void _paintMaximize(Canvas canvas, Paint paint, double unit) {
    canvas.drawRect(
      Rect.fromLTWH(0.5 * unit, 0.5 * unit, 9 * unit, 9 * unit),
      paint,
    );
  }

  void _paintRestore(Canvas canvas, Paint paint, double unit) {
    // The front square.
    canvas.drawRect(
      Rect.fromLTWH(0.5 * unit, 2.5 * unit, 7 * unit, 7 * unit),
      paint,
    );
    // The visible edges of the square behind it.
    final Path backSquareEdges = Path()
      ..moveTo(2.5 * unit, 2.5 * unit)
      ..lineTo(2.5 * unit, 0.5 * unit)
      ..lineTo(9.5 * unit, 0.5 * unit)
      ..lineTo(9.5 * unit, 7.5 * unit)
      ..lineTo(7.5 * unit, 7.5 * unit);
    canvas.drawPath(backSquareEdges, paint);
  }

  void _paintClose(Canvas canvas, Paint paint, double unit) {
    canvas.drawLine(Offset.zero, Offset(10 * unit, 10 * unit), paint);
    canvas.drawLine(Offset(10 * unit, 0), Offset(0, 10 * unit), paint);
  }

  @override
  bool shouldRepaint(WindowCaptionGlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// One of the Windows caption glyphs (minimize, maximize, restore, close) as a
/// widget, drawn the same way as on the caption buttons. Use it anywhere: in a
/// menu entry, a toolbar, your own caption buttons.
///
/// ```dart
/// WindowCaptionGlyphIcon(glyph: WindowCaptionGlyph.close, size: 12)
/// ```
class WindowCaptionGlyphIcon extends StatelessWidget {
  const WindowCaptionGlyphIcon({
    super.key,
    required this.glyph,
    this.size = 10,
    this.color,
    this.strokeWidth = 1,
  });

  final WindowCaptionGlyph glyph;

  /// Width and height (logical pixels). 10 is the size of Windows.
  final double size;

  /// The color. Default: the surrounding icon color (`IconTheme`).
  final Color? color;

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor =
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: WindowCaptionGlyphPainter(
          glyph: glyph,
          color: resolvedColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
