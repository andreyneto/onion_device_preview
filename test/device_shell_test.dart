import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

Future<void> _pumpAndSettle(WidgetTester tester, Widget child) async {
  // Same real-async-decode concern as onion_screen_test.dart's
  // _pumpWithDefaultTheme — the embedded OnionScreen kicks off real
  // image decoding as soon as it builds.
  await tester.runAsync(() async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: child));
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pump();
  });
}

void main() {
  group('MiyooDeviceShell', () {
    testWidgets('renders without throwing and embeds exactly one OnionScreen', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpAndSettle(tester, MiyooDeviceShell(controller: controller));

      expect(tester.takeException(), isNull);
      expect(find.byType(OnionScreen), findsOneWidget);
    });

    testWidgets('has 11 tappable regions: 4 d-pad + menu/start/select + X/Y/A/B', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpAndSettle(tester, MiyooDeviceShell(controller: controller));

      // The device's own buttons — 4 d-pad segments + menu + start +
      // select + X + Y + A + B — plus the one tap-to-refocus
      // GestureDetector the embedded OnionScreen wraps itself in.
      expect(find.byType(GestureDetector), findsNWidgets(12));
    });

    testWidgets('tapping A opens a main-menu tab, tapping B backs out', (tester) async {
      // Match the test viewport exactly to MiyooDeviceShell's logical
      // size so its FittedBox renders at a 1:1 scale with no letterboxing
      // offset — then the button centers below are the real on-screen
      // tap coordinates, not a guess about widget-tree traversal order.
      tester.view.physicalSize = MiyooDeviceShell.logicalSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpAndSettle(tester, MiyooDeviceShell(controller: controller));
      expect(controller.currentScreen, OnionScreenKind.mainMenu);

      // MainMenuScreen owns `onConfirm` once mounted (it activates
      // whichever tab is selected), so the observable effect of an A
      // press is navigation — not a custom callback the test could
      // inject ahead of time.
      // device_shell.dart: A is a 92-diameter circle at (top:683, left:569).
      await tester.tapAt(const Offset(569 + 46, 683 + 46));
      await tester.pump();
      expect(controller.currentScreen, isNot(OnionScreenKind.mainMenu));

      // device_shell.dart: B is a 92-diameter circle at (top:774, left:478).
      await tester.tapAt(const Offset(478 + 46, 774 + 46));
      await tester.pump();
      expect(controller.currentScreen, OnionScreenKind.mainMenu);
    });
  });
}
