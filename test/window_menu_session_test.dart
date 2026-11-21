import 'dart:ui' show Offset, Rect;

import 'package:flutter/gestures.dart'
    show kPrimaryButton, kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:window_frame/src/presentation/view_models/window_menu_session.dart';

void main() {
  const Rect icon = Rect.fromLTWH(0, 0, 30, 30);
  Duration now = Duration.zero;

  setUp(() {
    now = Duration.zero;
  });

  WindowMenuSession buildSession({
    bool openedByPress = false,
    bool canDrag = true,
    Rect? zone,
    Rect? anchor,
  }) {
    return WindowMenuSession(
      canDragWindowAt: (Offset _) => canDrag,
      doubleClickCloseZone: zone,
      anchorBounds: anchor,
      openedByPress: openedByPress,
      clock: () => now,
    );
  }

  group('WindowMenuSession', () {
    test('a right-click on the menu closes it and is remembered', () {
      final WindowMenuSession session = buildSession();

      final MenuPressOutcome outcome = session.onPointerDown(
        position: const Offset(50, 50),
        buttons: kSecondaryMouseButton,
        pointer: 1,
        device: 0,
        isOnMenu: true,
      );

      expect(outcome, MenuPressOutcome.closeMenu);
      expect(session.reopenPosition, const Offset(50, 50));
    });

    test('a left-click outside is remembered as the dismissing click', () {
      final WindowMenuSession session = buildSession();

      final MenuPressOutcome outcome = session.onPointerDown(
        position: const Offset(200, 10),
        buttons: kPrimaryButton,
        pointer: 1,
        device: 7,
        isOnMenu: false,
      );

      expect(outcome, MenuPressOutcome.none);
      expect(session.dismissingClick, const Offset(200, 10));
      expect(session.dismissingDevice, 7);
      expect(
        session.afterClose(hasSelectedItem: false),
        MenuClosedOutcome.noteDismissingClick,
      );
    });

    test('a quick second click in the zone asks the window to close', () {
      final WindowMenuSession session = buildSession(zone: icon);
      now += const Duration(milliseconds: 100);

      final MenuPressOutcome outcome = session.onPointerDown(
        position: const Offset(10, 10),
        buttons: kPrimaryButton,
        pointer: 1,
        device: 0,
        isOnMenu: false,
      );

      expect(outcome, MenuPressOutcome.hideForWindowClose);
      expect(
        session.afterClose(hasSelectedItem: false),
        MenuClosedOutcome.requestWindowClose,
      );
    });

    test('a slow second click in the zone is only a dismissing click', () {
      final WindowMenuSession session = buildSession(zone: icon);
      now += const Duration(seconds: 2);

      final MenuPressOutcome outcome = session.onPointerDown(
        position: const Offset(10, 10),
        buttons: kPrimaryButton,
        pointer: 1,
        device: 0,
        isOnMenu: false,
      );

      expect(outcome, MenuPressOutcome.none);
      expect(session.dismissingClick, const Offset(10, 10));
    });

    test('pressing the bar and moving far enough starts a window drag', () {
      final WindowMenuSession session = buildSession();
      session.onPointerDown(
        position: const Offset(200, 10),
        buttons: kPrimaryButton,
        pointer: 3,
        device: 0,
        isOnMenu: false,
      );

      expect(
        session.onPointerMove(position: const Offset(202, 10), pointer: 3),
        isFalse,
      );
      expect(
        session.onPointerMove(position: const Offset(230, 10), pointer: 3),
        isTrue,
      );
      expect(session.dismissingClick, isNull);
      expect(
        session.onPointerMove(position: const Offset(260, 10), pointer: 3),
        isFalse,
      );
    });

    test('no window drag when the press was not on a drag handle', () {
      final WindowMenuSession session = buildSession(canDrag: false);
      session.onPointerDown(
        position: const Offset(200, 10),
        buttons: kPrimaryButton,
        pointer: 3,
        device: 0,
        isOnMenu: false,
      );

      expect(
        session.onPointerMove(position: const Offset(300, 10), pointer: 3),
        isFalse,
      );
    });

    test('releasing over an entry runs it when the menu opened by press', () {
      final WindowMenuSession session = buildSession(
        openedByPress: true,
        anchor: icon,
      );

      final MenuReleaseOutcome outcome = session.onPointerUp(
        position: const Offset(60, 60),
        pointer: 1,
        isOverEnabledItem: true,
        isOnMenu: true,
      );

      expect(outcome, MenuReleaseOutcome.runItem);
    });

    test('releasing over the icon or the menu leaves the menu open', () {
      final WindowMenuSession onIcon = buildSession(
        openedByPress: true,
        anchor: icon,
      );
      final WindowMenuSession onMenu = buildSession(
        openedByPress: true,
        anchor: icon,
      );

      expect(
        onIcon.onPointerUp(
          position: const Offset(10, 10),
          pointer: 1,
          isOverEnabledItem: false,
          isOnMenu: false,
        ),
        MenuReleaseOutcome.none,
      );
      expect(
        onMenu.onPointerUp(
          position: const Offset(60, 60),
          pointer: 1,
          isOverEnabledItem: false,
          isOnMenu: true,
        ),
        MenuReleaseOutcome.none,
      );
    });

    test('releasing anywhere else closes a menu opened by press', () {
      final WindowMenuSession session = buildSession(
        openedByPress: true,
        anchor: icon,
      );

      final MenuReleaseOutcome outcome = session.onPointerUp(
        position: const Offset(400, 400),
        pointer: 1,
        isOverEnabledItem: false,
        isOnMenu: false,
      );

      expect(outcome, MenuReleaseOutcome.closeMenu);
    });

    test('only the first release of a menu opened by press counts', () {
      final WindowMenuSession session = buildSession(openedByPress: true);
      session.onPointerUp(
        position: const Offset(10, 10),
        pointer: 1,
        isOverEnabledItem: false,
        isOnMenu: true,
      );

      final MenuReleaseOutcome second = session.onPointerUp(
        position: const Offset(400, 400),
        pointer: 1,
        isOverEnabledItem: false,
        isOnMenu: false,
      );

      expect(second, MenuReleaseOutcome.none);
    });

    test('a press on the icon of this same menu is not handed over', () {
      final WindowMenuSession session = buildSession(anchor: icon);

      expect(
        session.shouldOfferHandOver(
          position: const Offset(10, 10),
          buttons: kPrimaryButton,
        ),
        isFalse,
      );
      expect(
        session.shouldOfferHandOver(
          position: const Offset(300, 10),
          buttons: kPrimaryButton,
        ),
        isTrue,
      );
    });

    test('a menu that was handed over ignores everything afterwards', () {
      final WindowMenuSession session = buildSession();

      session.markHandedOver();

      expect(session.handedOver, isTrue);
      expect(
        session.shouldOfferHandOver(
          position: const Offset(300, 10),
          buttons: kPrimaryButton,
        ),
        isFalse,
      );
      expect(
        session.afterClose(hasSelectedItem: true),
        MenuClosedOutcome.nothing,
      );
    });

    test('after close, a picked entry wins over everything else', () {
      final WindowMenuSession session = buildSession();
      session.onPointerDown(
        position: const Offset(50, 50),
        buttons: kSecondaryMouseButton,
        pointer: 1,
        device: 0,
        isOnMenu: false,
      );

      expect(
        session.afterClose(hasSelectedItem: true),
        MenuClosedOutcome.runItem,
      );
      expect(
        session.afterClose(hasSelectedItem: false),
        MenuClosedOutcome.reopenMenu,
      );
    });

    test('after close with nothing happened there is nothing to do', () {
      final WindowMenuSession session = buildSession();

      expect(
        session.afterClose(hasSelectedItem: false),
        MenuClosedOutcome.nothing,
      );
    });
  });
}
