import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/core/asset_resolver.dart';

/// A valid, decodable 1x1 red-pixel PNG — used so "found in the theme zip"
/// assertions exercise real image decoding, not just byte presence.
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

OnionThemeBundle _bundleWithFile(String path, List<int> bytes) {
  return OnionThemeBundle.fromZipBytes(_buildZip({
    'config.json': utf8.encode('{"name":"Test"}'),
    path: bytes,
  }));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetResolver', () {
    test('resolves an asset present in the theme zip and marks it found-in-theme', () async {
      final bundle = _bundleWithFile('skin/bg-title.png', _tinyPng);
      final resolver = AssetResolver(bundle);

      final image = await resolver.resolve(ThemeAsset.bgTitle);

      expect(image, isNotNull);
      expect(image!.width, 1);
      expect(resolver.foundInTheme, contains(ThemeAsset.bgTitle));
      expect(resolver.foundInDefault, isEmpty);
      expect(resolver.missing, isEmpty);
    });

    test('falls back to the bundled default skin when the theme lacks the asset', () async {
      final resolver = AssetResolver(OnionThemeBundle.defaultTheme());

      final image = await resolver.resolve(ThemeAsset.bgTitle);

      expect(image, isNotNull);
      expect(resolver.foundInTheme, isEmpty);
      expect(resolver.foundInDefault, contains(ThemeAsset.bgTitle));
    });

    test('an asset present in neither the theme nor the default skin resolves to null', () async {
      final resolver = AssetResolver(OnionThemeBundle.defaultTheme());

      // lowBat is one of the optional extra/ assets not shipped in the
      // firmware's own default skin (see plan.md §3 — extra/ is empty
      // in the default build; only present when a theme provides it).
      final image = await resolver.resolve(ThemeAsset.lowBat);

      expect(image, isNull);
      expect(resolver.missing, contains(ThemeAsset.lowBat));
    });

    test('caches the decoded image on repeated resolves', () async {
      final resolver = AssetResolver(OnionThemeBundle.defaultTheme());

      final first = await resolver.resolve(ThemeAsset.bgTitle);
      final second = await resolver.resolve(ThemeAsset.bgTitle);

      expect(identical(first, second), isTrue);
    });
  });
}
