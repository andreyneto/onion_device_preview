// Not behavioral tests: renders each calibrated screen at native 640x480
// into PNGs for external pixel comparison against the real-device
// screenshots (MainUI_004..012 — docs/spec-1a1.md conformance loop).
// Kept in test/ because it needs the flutter_test harness to drive real
// frames. Set ONION_RENDER_DIR to collect the files; without it they go
// to the system temp dir.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

Future<void> _renderTo(WidgetTester tester, OnionPreviewController controller, String name) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await tester.pump();

  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Platform.environment['ONION_RENDER_DIR'] ?? Directory.systemTemp.path;
  File('$dir/render_$name.png').writeAsBytesSync(byteData!.buffer.asUint8List());
}

void main() {
  testWidgets('renders calibrated screens to 640x480 pngs for pixel comparison', (tester) async {
    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      final loader = FontLoader('packages/onion_device_preview/Exo 2 Bold Italic')
        ..addFont(rootBundle.load('packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf'));
      await loader.load();

      // The .ttc fallback family. Real runtimes ship Roboto; the test
      // harness doesn't, so load it from the SDK's material fonts to
      // keep these renders faithful.
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      if (flutterRoot != null) {
        final robotoFile = File('$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
        if (robotoFile.existsSync()) {
          final bytes = robotoFile.readAsBytesSync();
          final roboto = FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)));
          await roboto.load();
        }
      }

      final controller = OnionPreviewController()
        ..setBatteryPercent(97)
        ..setWifi(OnionWifiState.signal2)
        ..resetTo(OnionScreenKind.mainMenu);
      await controller.loadTheme(controller.theme);

      await _renderTo(tester, controller, 'main_menu');

      controller.goTo(OnionScreenKind.gameSystems);
      await _renderTo(tester, controller, 'game_systems');

      final arcade = OnionMockData.gameSystems.last;
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openGameList(arcade.roms, arcade.name);
      await _renderTo(tester, controller, 'game_list');

      controller.showPopMenu(const ['Launch', 'Clear list'], onSelect: (_) {});
      await _renderTo(tester, controller, 'pop_menu');

      controller.goBack();
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openSettingsTree(OnionMockData.settings, 'Settings');
      await _renderTo(tester, controller, 'settings');
    });
  });
}
