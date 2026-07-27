import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/boot_screen.dart';
import 'package:onion_device_preview/src/screens/charging_screen.dart';
import 'package:onion_device_preview/src/screens/shutdown_screen.dart';
import 'package:onion_device_preview/src/screens/widgets/battery_indicator.dart';
import 'package:onion_device_preview/src/screens/widgets/boot_style_screen.dart';

Future<OnionPreviewController> _pump(WidgetTester tester, OnionScreenKind screen) async {
  final controller = OnionPreviewController();
  await tester.runAsync(() async {
    await controller.loadTheme(OnionThemeBundle.defaultTheme());
    controller.resetTo(screen);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await tester.pump();
  });
  return controller;
}

void main() {
  testWidgets('the bundled skin serves the boot logo and the shutdown art', (tester) async {
    // Both are extra/ assets, which fall back to the *app's* res/ dir on
    // the device (load.h:57-60) — bootScreen's own res/. Without them
    // embedded, the boot screen has no logo and shutdown is blank.
    final controller = OnionPreviewController();
    late ThemeRenderContext ctx;
    await tester.runAsync(() async {
      await controller.loadTheme(OnionThemeBundle.defaultTheme());
      ctx = controller.renderContext!;
    });

    expect(ctx.image(ThemeAsset.bootScreen), isNotNull);
    expect(ctx.image(ThemeAsset.screenOff), isNotNull);
    expect(ctx.image(ThemeAsset.screenOffSave), isNotNull);
    expect(ctx.assetsFromDefaultSkin, contains(ThemeAsset.bootScreen));
  });

  testWidgets('boot shows the version but no battery', (tester) async {
    await _pump(tester, OnionScreenKind.boot);

    expect(find.byType(BootScreen), findsOneWidget);
    final splash = tester.widget<BootStyleScreen>(find.byType(BootStyleScreen));
    expect(splash.background, isNotNull, reason: 'the logo art must resolve');
    expect(splash.version, kPreviewVersionString);
    // bootScreen.c:36 — show_battery is false for `Boot`.
    expect(splash.batteryStyle, isNull);
    expect(find.byType(BatteryIndicator), findsNothing);
  });

  testWidgets('shutdown shows the art, the version and the battery', (tester) async {
    final controller = await _pump(tester, OnionScreenKind.shutdown);

    expect(find.byType(ShutdownScreen), findsOneWidget);
    final splash = tester.widget<BootStyleScreen>(find.byType(BootStyleScreen));
    expect(splash.background, isNotNull);
    expect(splash.version, kPreviewVersionString);
    // `bootScreen "End"` is called with no message argument.
    expect(splash.message, isEmpty);
    // show_battery is true for both End variants.
    expect(splash.batteryStyle, isNotNull);
    expect(find.byType(BatteryIndicator), findsOneWidget);

    // End_Save swaps the background art.
    final normalArt = splash.background;
    controller.setShutdownSaving(true);
    await tester.pump();
    expect(tester.widget<BootStyleScreen>(find.byType(BootStyleScreen)).background, isNot(normalArt));
  });

  test('charging frame delay follows the sidecar, floored at the firmware default', () {
    // No sidecar → the firmware's own default.
    expect(chargingFrameDelayMs(null), kChargingDefaultDelayMs);
    // Authored values above the floor are honored as-is.
    expect(chargingFrameDelayMs(500), 500);
    expect(chargingFrameDelayMs(80), 80);
    // 10000+ is microseconds, integer-divided (chargingState.c:130-131).
    expect(chargingFrameDelayMs(500000), 500);
    expect(chargingFrameDelayMs(10000), kChargingDefaultDelayMs, reason: '10ms → floored');
    // Below the floor — including the stock sidecar's 15ms, which is the
    // loop's msleep and not a rate the hardware can sustain.
    expect(chargingFrameDelayMs(15), kChargingDefaultDelayMs);
    expect(chargingFrameDelayMs(1), kChargingDefaultDelayMs);
    expect(kChargingMinDelayMs, lessThan(kChargingDefaultDelayMs));
  });
}
