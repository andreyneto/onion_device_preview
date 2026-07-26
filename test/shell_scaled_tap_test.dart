import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// Regression check for the exact browser scenario that broke A/B: the
/// shell scaled down by its FittedBox (not 1:1 like device_shell_test)
/// AND the app going through the real boot → main menu transition, whose
/// late BootScreen dispose used to clobber the main menu's just-bound
/// confirm handler when handlers were a single mutable slot.
void main() {
  testWidgets('tapping A works through a scaled-down shell after the real boot flow', (tester) async {
    tester.view.physicalSize = const Size(1498, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = OnionPreviewController(); // starts at boot, like the example app

    await tester.runAsync(() async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: MiyooDeviceShell(controller: controller)),
        ),
      );
      // Real time for asset resolution to land and BootScreen to mount…
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
      // …then real time again for its 1.5s auto-advance timer (created
      // just now, on mount) to fire.
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
    });
    await tester.pump(const Duration(seconds: 2));
    expect(controller.currentScreen, OnionScreenKind.mainMenu);

    // Shell logical 694x999 fitted into 820px height → scale 820/999.
    const scale = 820 / 999;
    const shellTopLeft = Offset((1498 - 694 * scale) / 2, 0);
    // A button: circle at logical (569, 683), diameter 92 → center (615, 729).
    final aCenter = shellTopLeft + const Offset(615, 729) * scale;

    // Select the Games tab (index 1 of the stock 4), then press A.
    controller.moveRight();
    await tester.pump();
    await tester.tapAt(aCenter);
    await tester.pump();

    expect(controller.currentScreen, OnionScreenKind.gameSystems,
        reason: 'tapping A on the scaled shell must activate the focused tab');
  });
}
