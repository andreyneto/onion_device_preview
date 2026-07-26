import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// T6.2 — robustness against every real theme in the sibling `Themes/`
/// checkout: the tolerant parser must swallow all 249+ community
/// `config.json`s without throwing, and a few representative themes must
/// survive the full bundle → render-context pipeline end to end.
///
/// Skipped silently when `../Themes` isn't checked out next to this
/// package (e.g. a standalone CI of just this repo).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final themesDir = Directory('${Directory.current.path}/../Themes/themes');

  group('real Themes/ repository', () {
    test('every config.json parses without throwing', () {
      if (!themesDir.existsSync()) {
        markTestSkipped('../Themes not checked out');
        return;
      }

      var parsed = 0;
      final failures = <String>[];
      for (final entry in themesDir.listSync()) {
        if (entry is! Directory) continue;
        final configFile = File('${entry.path}/config.json');
        if (!configFile.existsSync()) continue;
        try {
          final json = jsonDecode(configFile.readAsStringSync());
          if (json is Map<String, dynamic>) {
            OnionThemeConfig.fromJson(json);
          }
          // Malformed top-level JSON is the bundle layer's problem (it
          // falls back to defaults) — only a *throwing parser* fails here.
          parsed++;
        } catch (e) {
          failures.add('${entry.path}: $e');
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
      // ~180 of the 249 theme dirs have a decodable top-level JSON map;
      // the rest are handled by the bundle layer's defaults fallback.
      expect(parsed, greaterThan(150), reason: 'sanity: the Themes checkout should have 150+ parseable configs');
    });

    test('representative themes resolve end to end (bundle -> render context)', () async {
      if (!themesDir.existsSync()) {
        markTestSkipped('../Themes not checked out');
        return;
      }

      for (final name in ['Blueprint by Aemiii91', 'win98 by kyhynngy_oyuur', 'AmalgaM by ZaxxonQ']) {
        final dir = Directory('${themesDir.path}/$name');
        if (!dir.existsSync()) {
          markTestSkipped('$name missing from Themes checkout');
          continue;
        }

        final bundle = OnionThemeBundle.fromZipBytes(_zipDirectory(dir));
        final context = await ThemeRenderContext.resolve(bundle);

        expect(context.config, isNotNull);
        expect(context.image(ThemeAsset.background), isNotNull, reason: '$name must have a background');
      }
    });
  });
}

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
