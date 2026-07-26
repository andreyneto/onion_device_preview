// Not a behavioral test: renders the main menu with real community
// themes from the sibling Themes/ checkout, for visual comparison
// against each theme's own preview.png (T6.3 acceptance). Skipped when
// ../Themes isn't present. Set ONION_RENDER_DIR to collect the files.
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
  testWidgets('renders the main menu with real themes for visual comparison', (tester) async {
    final themesDir = Directory('${Directory.current.path}/../Themes/themes');
    if (!themesDir.existsSync()) {
      markTestSkipped('../Themes not checked out');
      return;
    }

    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      final exo = FontLoader('packages/onion_device_preview/Exo 2 Bold Italic')
        ..addFont(rootBundle.load('packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf'));
      await exo.load();
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      if (flutterRoot != null) {
        final robotoFile = File('$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
        if (robotoFile.existsSync()) {
          final bytes = robotoFile.readAsBytesSync();
          final roboto = FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)));
          await roboto.load();
        }
      }

      final dir = Platform.environment['ONION_RENDER_DIR'] ?? Directory.systemTemp.path;

      for (final name in ['Blueprint by Aemiii91', 'win98 by kyhynngy_oyuur', 'AmalgaM by ZaxxonQ']) {
        final themeDir = Directory('${themesDir.path}/$name');
        if (!themeDir.existsSync()) continue;

        final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);
        final swapped = await controller.loadTheme(OnionThemeBundle.fromZipBytes(_zipDirectory(themeDir)));
        expect(swapped, isTrue, reason: '$name must load');

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
        final slug = name.split(' ').first.toLowerCase();
        File('$dir/render_theme_$slug.png').writeAsBytesSync(byteData!.buffer.asUint8List());
        controller.dispose();
      }
    });
  });
}
