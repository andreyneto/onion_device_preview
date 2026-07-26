import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

const _tinyPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, //
  0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 248, 207, 80, 15, 0, //
  3, 134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, //
  174, 66, 96, 130, //
];

Uint8List _buildZip(Map<String, List<int>> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) {
    final data = Uint8List.fromList(bytes);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

Future<void> _pumpInspector(WidgetTester tester, OnionPreviewController controller) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(child: ThemeInspector(controller: controller)),
    ),
  );
}

void main() {
  group('ThemeInspector', () {
    testWidgets('shows theme name and marks theme-set vs default config values', (tester) async {
      final controller = OnionPreviewController();
      await tester.runAsync(() async {
        await controller.loadTheme(OnionThemeBundle.fromZipBytes(_buildZip({
          'config.json': utf8.encode('{"name":"MyTheme","author":"Me","title":{"size":30}}'),
          'skin/background.png': _tinyPng,
        })));
      });

      await _pumpInspector(tester, controller);

      expect(find.text('MyTheme'), findsOneWidget);
      expect(find.text('por Me'), findsOneWidget);
      // title.size was set by the theme; everything else fell back —
      // both badge kinds must therefore be present.
      expect(find.text('tema'), findsWidgets);
      expect(find.text('default'), findsWidgets);
    });

    testWidgets('reports found/default/missing asset counts from the render context', (tester) async {
      final controller = OnionPreviewController();
      await tester.runAsync(() async {
        await controller.loadTheme(OnionThemeBundle.fromZipBytes(_buildZip({
          'config.json': utf8.encode('{"name":"T"}'),
          'skin/background.png': _tinyPng,
        })));
      });

      await _pumpInspector(tester, controller);

      expect(find.text('Assets — do tema (1)'), findsOneWidget);
      final ctx = controller.renderContext!;
      expect(find.text('Assets — do skin default (${ctx.assetsFromDefaultSkin.length})'), findsOneWidget);
      expect(find.text('Assets — ausentes (${ctx.assetsMissing.length})'), findsOneWidget);
    });

    testWidgets('surfaces a failed theme load without losing the previous theme', (tester) async {
      final controller = OnionPreviewController();
      await tester.runAsync(() async {
        await controller.loadTheme(OnionThemeBundle.defaultTheme());
      });

      await _pumpInspector(tester, controller);

      expect(find.text('Silky'), findsOneWidget);
      expect(find.textContaining('Falha ao carregar'), findsNothing);
    });
  });
}
