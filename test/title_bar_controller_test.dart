import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/window_frame.dart';

void main() {
  group('TitleBarController', () {
    test('starts with its initial content', () {
      final TitleBarController controller = TitleBarController(
        initialContent: const TitleBarContent(title: 'Start'),
      );

      expect(controller.content.title, 'Start');
    });

    test('setTitle changes only the title and notifies', () {
      final TitleBarController controller = TitleBarController(
        initialContent: const TitleBarContent(
          title: 'Start',
          backgroundColor: Colors.blue,
        ),
      );
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setTitle('Changed');

      expect(controller.content.title, 'Changed');
      expect(controller.content.backgroundColor, Colors.blue);
      expect(notifications, 1);
    });

    test('update keeps the fields it does not set', () {
      final TitleBarController controller = TitleBarController(
        initialContent: const TitleBarContent(title: 'Start', spacing: 6),
      );

      controller.update(const TitleBarContent(spacing: 10));

      expect(controller.content.title, 'Start');
      expect(controller.content.spacing, 10);
    });

    test('replace swaps the whole content', () {
      final TitleBarController controller = TitleBarController(
        initialContent: const TitleBarContent(title: 'Start', spacing: 6),
      );

      controller.replace(const TitleBarContent(title: 'New'));

      expect(controller.content.title, 'New');
      expect(controller.content.spacing, isNull);
    });

    test('reset goes back to inheriting everything', () {
      final TitleBarController controller = TitleBarController(
        initialContent: const TitleBarContent(title: 'Start'),
      );

      controller.reset();

      expect(controller.content.title, isNull);
    });

    test('a disposed controller ignores later changes', () {
      final TitleBarController controller = TitleBarController();
      controller.dispose();

      expect(() => controller.setTitle('Late'), returnsNormally);
    });
  });
}
