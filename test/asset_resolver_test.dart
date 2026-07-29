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

  // Mirrors the firmware's thresholds in `render/battery.h:7-20`. The
  // logical names carry a literal `%`, and all six files ship in 242+ of
  // the themes in the repo, so a mismatch here would silently render the
  // default skin's battery over someone's theme.
  group('batteryAssetFor', () {
    test('maps each charge level to the firmware\'s asset', () {
      expect(batteryAssetFor(0), ThemeAsset.battery0);
      expect(batteryAssetFor(4), ThemeAsset.battery0);
      expect(batteryAssetFor(5), ThemeAsset.battery20);
      expect(batteryAssetFor(29), ThemeAsset.battery20);
      expect(batteryAssetFor(30), ThemeAsset.battery50);
      expect(batteryAssetFor(59), ThemeAsset.battery50);
      expect(batteryAssetFor(60), ThemeAsset.battery80);
      expect(batteryAssetFor(89), ThemeAsset.battery80);
      expect(batteryAssetFor(90), ThemeAsset.batteryFull);
      expect(batteryAssetFor(100), ThemeAsset.batteryFull);
    });

    test('charging wins over the charge level', () {
      for (final percentage in [0, 50, 100]) {
        expect(batteryAssetFor(percentage, charging: true), ThemeAsset.batteryCharging);
      }
    });

    test('resolves to the file names themes actually ship', () {
      expect(batteryAssetFor(0).skinPath, 'skin/power-0%-icon.png');
      expect(batteryAssetFor(20).skinPath, 'skin/power-20%-icon.png');
      expect(batteryAssetFor(50).skinPath, 'skin/power-50%-icon.png');
      expect(batteryAssetFor(80).skinPath, 'skin/power-80%-icon.png');
      expect(batteryAssetFor(100).skinPath, 'skin/power-full-icon.png');
      expect(
        batteryAssetFor(100, charging: true).skinPath,
        'skin/ic-power-charge-100%.png',
      );
    });

    test('every battery asset is covered by the bundled default skin', () async {
      final resolver = AssetResolver(OnionThemeBundle.defaultTheme());

      for (final percentage in [0, 20, 50, 80, 100]) {
        expect(await resolver.resolve(batteryAssetFor(percentage)), isNotNull);
      }
      expect(await resolver.resolve(batteryAssetFor(50, charging: true)), isNotNull);
    });
  });
}
