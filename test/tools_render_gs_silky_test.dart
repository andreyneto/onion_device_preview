// Not a behavioral test: renders the Game Switcher with "Silky by DiMo"
// from the sibling Themes/ checkout — the theme the device screenshots in
// test/fixtures/device/ were taken with. The *bundled* default skin is the
// firmware's own Silky, which ships no skin/extra/, so it can never
// exercise the custom gs-top-bar / gs-bottom-bar path these captures show.
// Skipped when ../Themes isn't present. Set ONION_RENDER_DIR to collect.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

Uint8List _zipDirectory(Directory dir) {
  final archive = Archive();
  for (final entry in dir.listSync(recursive: true)) {
    if (entry is! File) continue;
    final relative = entry.path.substring(dir.path.length + 1);
    final bytes = entry.readAsBytesSync();
    archive.addFile(ArchiveFile(relative, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  testWidgets('renders the Game Switcher with the Themes-repo Silky', (tester) async {
    final themeDir = Directory('${Directory.current.path}/../Themes/themes/Silky by DiMo');
    if (!themeDir.existsSync()) {
      markTestSkipped('../Themes not checked out');
      return;
    }

    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dir = Platform.environment['ONION_RENDER_DIR'] ?? Directory.systemTemp.path;
    final key = GlobalKey();

    await tester.runAsync(() async {
      final exo = FontLoader('packages/onion_device_preview/Exo 2 Bold Italic')
        ..addFont(rootBundle.load('packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf'));
      await exo.load();

      // Battery 95%, matching the captures.
      final controller = OnionPreviewController()
        ..setBatteryPercent(95)
        ..setWifi(OnionWifiState.off)
        ..resetTo(OnionScreenKind.mainMenu);
      expect(await controller.loadTheme(OnionThemeBundle.fromZipBytes(_zipDirectory(themeDir))), isTrue);

      controller.openGameSwitcher();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
          ),
        ),
      );

      Future<void> shot(String name) async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await tester.pump();
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/render_silky_$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      }

      await shot('gs');

      // First-run state: no history, so the centered `Empty` art and
      // nothing else over the black background.
      controller.setGsHistoryEmpty(true);
      await shot('gs_empty');
      controller.setGsHistoryEmpty(false);

      // The switcher's delete confirmation — same strings as
      // gs_keystate.h:81-82, and the screen the device capture shows.
      controller.showDialog(
        title: 'Remove from history',
        message: 'Are you sure you want to\nremove game from history?',
        showHint: true,
      );
      await shot('gs_dialog');
      controller.goBack();

      controller.cycleGsHeader();
      controller.cycleGsHeader();
      await shot('gs_time');

      controller.showPopMenu(const ['Resume', 'Save', 'Load', 'Exit to menu'], onSelect: (_) {});
      await shot('gs_pop_menu');


      controller.dispose();
    });
  });
}
