import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/window_frame.dart';

void main() {
  group('WindowFrameOptions', () {
    test('has the documented defaults', () {
      const WindowFrameOptions options = WindowFrameOptions();

      expect(options.minimumSize, const Size(800, 600));
      expect(options.startMaximized, isFalse);
      expect(options.customFrame, isTrue);
      expect(options.frameBorderWidth, 0);
    });

    test('keeps the frame border width it was given', () {
      const WindowFrameOptions options = WindowFrameOptions(
        frameBorderWidth: 2,
      );

      expect(options.frameBorderWidth, 2);
    });

    test('rejects a negative frame border width', () {
      final int negativeWidth = -1;

      expect(
        () => WindowFrameOptions(frameBorderWidth: negativeWidth),
        throwsAssertionError,
      );
    });
  });

  group('WindowCaptionGlyphIcon', () {
    testWidgets('is drawn at the requested size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: WindowCaptionGlyphIcon(
              glyph: WindowCaptionGlyph.close,
              size: 14,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(WindowCaptionGlyphIcon)),
        const Size(14, 14),
      );
    });
  });
}
