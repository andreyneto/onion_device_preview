import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/boot_screen.dart';
import 'package:onion_device_preview/src/screens/main_menu_screen.dart';
import 'package:onion_device_preview/src/screens/settings_list_screen.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_footer.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_header.dart';

Future<void> _pumpWithDefaultTheme(
  WidgetTester tester,
  OnionPreviewController controller, {
  OnionZoom zoom = OnionZoom.fit,
}) async {
  // OnionScreen.initState kicks off ThemeRenderContext.resolve() (real
  // engine-level async work: rootBundle.load + instantiateImageCodec per
  // asset) as soon as pumpWidget builds it. That Future is bound to
  // whatever zone it's created in — creating it outside runAsync binds it
  // to FakeAsync, where real async work never actually progresses no
  // matter how much *unrelated* real time we wait elsewhere. So the
  // pumpWidget call itself (not just a later wait) has to happen inside
  // runAsync, and we keep pumping — in real time — until it resolves.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: OnionScreen(controller: controller, zoom: zoom)),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pump();
  });
}

void main() {
  group('OnionScreen', () {
    testWidgets('boot is a full-screen splash with no header/footer chrome', (tester) async {
      final controller = OnionPreviewController();

      await _pumpWithDefaultTheme(tester, controller);

      expect(tester.takeException(), isNull);
      expect(find.byType(BootScreen), findsOneWidget);
      expect(find.byType(ThemeHeader), findsNothing);
      expect(find.byType(ThemeFooter), findsNothing);
    });

    testWidgets('renders the header and footer chrome around the main menu', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpWithDefaultTheme(tester, controller);

      expect(tester.takeException(), isNull);
      expect(find.byType(ThemeHeader), findsOneWidget);
      expect(find.byType(ThemeFooter), findsOneWidget);
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('scales to a fixed 640x480 logical size', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpWithDefaultTheme(tester, controller);

      expect(tester.getSize(find.byType(OnionScreen)), const Size(640, 480));
    });

    testWidgets('a fixed zoom renders at an exact pixel-perfect multiple, not fit-to-parent', (tester) async {
      // The default 800x600 test viewport is smaller than 1280x960 (640x480
      // at x2) — under Center's loose constraints that would just clamp
      // the SizedBox down to the viewport, so give it enough room first.
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpWithDefaultTheme(tester, controller, zoom: OnionZoom.x2);

      expect(tester.getSize(find.byType(OnionScreen)), const Size(1280, 960));
    });

    testWidgets('navigating from the main menu to settings swaps the body screen', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpWithDefaultTheme(tester, controller);
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.byType(SettingsListScreen), findsNothing);

      controller.openSettingsTree(OnionMockData.settings, 'Settings');
      await tester.pump();

      expect(find.byType(MainMenuScreen), findsNothing);
      expect(find.byType(SettingsListScreen), findsOneWidget);
    });

    testWidgets('battery/charging changes update without re-resolving the theme', (tester) async {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);

      await _pumpWithDefaultTheme(tester, controller);

      controller.setBatteryPercent(10);
      controller.setCharging(true);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
