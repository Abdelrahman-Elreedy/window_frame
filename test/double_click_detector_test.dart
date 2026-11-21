import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/src/presentation/view_models/double_click_detector.dart';

void main() {
  group('DoubleClickDetector', () {
    Duration now = Duration.zero;

    setUp(() {
      now = Duration.zero;
    });

    DoubleClickDetector buildDetector({double? maxDistance}) {
      return DoubleClickDetector(maxDistance: maxDistance, clock: () => now);
    }

    test('two close clicks in time make a double-click', () {
      final DoubleClickDetector detector = buildDetector(maxDistance: 8);

      expect(detector.register(const Offset(10, 10)), isFalse);
      now += const Duration(milliseconds: 100);
      expect(detector.register(const Offset(12, 10)), isTrue);
    });

    test('a second click that comes too late is a new first click', () {
      final DoubleClickDetector detector = buildDetector(maxDistance: 8);

      detector.register(const Offset(10, 10));
      now += const Duration(milliseconds: 600);

      expect(detector.register(const Offset(10, 10)), isFalse);
    });

    test('a second click too far away is not a double-click', () {
      final DoubleClickDetector detector = buildDetector(maxDistance: 8);

      detector.register(const Offset(10, 10));
      now += const Duration(milliseconds: 100);

      expect(detector.register(const Offset(100, 10)), isFalse);
    });

    test('without a max distance only the time counts', () {
      final DoubleClickDetector detector = buildDetector();

      detector.note(const Offset(0, 0));
      now += const Duration(milliseconds: 100);

      expect(detector.isDoubleClickAt(const Offset(500, 500)), isTrue);
    });

    test('a double-click is forgotten: the third click starts again', () {
      final DoubleClickDetector detector = buildDetector(maxDistance: 8);

      detector.register(const Offset(10, 10));
      expect(detector.register(const Offset(10, 10)), isTrue);

      expect(detector.register(const Offset(10, 10)), isFalse);
    });

    test('forget removes the remembered click', () {
      final DoubleClickDetector detector = buildDetector();

      detector.note(const Offset(1, 1));
      detector.forget();

      expect(detector.isDoubleClickAt(const Offset(1, 1)), isFalse);
    });
  });
}
