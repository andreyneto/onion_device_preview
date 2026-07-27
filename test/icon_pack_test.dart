import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/core/icon_pack.dart';

/// A valid, decodable 1x1 PNG (same fixture as `asset_resolver_test.dart`),
/// so "found in the pack" assertions exercise real decoding.
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

OnionThemeBundle _bundleWith(Map<String, List<int>> files, {String prefix = ''}) {
  return OnionThemeBundle.fromZipBytes(_buildZip({
    '${prefix}config.json': utf8.encode('{"name":"Test"}'),
    '${prefix}skin/bg-title.png': _tinyPng,
    for (final entry in files.entries) '$prefix${entry.key}': entry.value,
  }));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IconPackResolver', () {
    test('resolves a system icon from the theme pack', () async {
      final resolver = IconPackResolver(_bundleWith({'icons/gba.png': _tinyPng}));

      final icon = await resolver.resolve('gba');

      expect(icon.image, isNotNull);
      expect(icon.source, IconPackSource.theme);
      expect(resolver.themeHasIconPack, isTrue);
    });

    test('falls back to the bundled Default pack per icon', () async {
      // The theme ships icons/, but not this one (the device's
      // apply_iconPack(..., reset_default: true) — installTheme.h:208).
      final resolver = IconPackResolver(_bundleWith({'icons/gba.png': _tinyPng}));

      final icon = await resolver.resolve('sfc');

      expect(icon.image, isNotNull);
      expect(icon.source, IconPackSource.defaultPack);
    });

    test('an icon in neither pack resolves to null', () async {
      final resolver = IconPackResolver(OnionThemeBundle.defaultTheme());

      final icon = await resolver.resolve('dreamcast');

      expect(icon.image, isNull);
      expect(icon.source, IconPackSource.missing);
    });

    test('app icons live under the pack\'s app/ sub-tree', () async {
      final resolver = IconPackResolver(_bundleWith({'icons/app/retroarch.png': _tinyPng}));

      final icon = await resolver.resolve('app/retroarch');

      expect(icon.source, IconPackSource.theme);
      // The plain name is a *different* icon, not the app one.
      expect((await resolver.resolve('retroarch')).source, IconPackSource.missing);
    });

    test('selected uses the pack\'s sel/ variant when present', () async {
      final resolver = IconPackResolver(_bundleWith({
        'icons/gba.png': _tinyPng,
        'icons/sel/gba.png': _tinyPng,
      }));

      final selected = await resolver.resolve('gba', selected: true);

      expect(selected.source, IconPackSource.theme);
      expect(resolver.sources.keys, contains('sel/gba'));
    });

    test('selected falls back to the normal icon without a sel/ variant', () async {
      final resolver = IconPackResolver(_bundleWith({'icons/gba.png': _tinyPng}));

      final normal = await resolver.resolve('gba');
      final selected = await resolver.resolve('gba', selected: true);

      expect(identical(normal.image, selected.image), isTrue);
    });

    test('app sel/ variant sits inside app/ (app/sel/<name>)', () async {
      final resolver = IconPackResolver(_bundleWith({
        'icons/app/retroarch.png': _tinyPng,
        'icons/app/sel/retroarch.png': _tinyPng,
      }));

      await resolver.resolve('app/retroarch', selected: true);

      expect(resolver.sources.keys, contains('app/sel/retroarch'));
    });

    test('an -alt name falls back to the base icon', () async {
      // apply_icons.h:143-144 cuts the config's icon basename at the
      // first '-', so `gba-alt` looks up the pack's `gba.png`.
      final resolver = IconPackResolver(_bundleWith({'icons/gba.png': _tinyPng}));

      final icon = await resolver.resolve('gba-alt');

      expect(icon.image, isNotNull);
      expect(resolver.sources.keys, contains('gba'));
    });

    test('a hyphenated name that exists is preferred over its prefix', () async {
      final resolver = IconPackResolver(_bundleWith({
        'icons/rapp/pico-8.png': _tinyPng,
        'icons/rapp/pico.png': _tinyPng,
      }));

      await resolver.resolve('rapp/pico-8');

      expect(resolver.sources.keys, contains('rapp/pico-8'));
      expect(resolver.sources.keys, isNot(contains('rapp/pico')));
    });

    test('applyThemeIcons: false ignores the theme pack entirely', () async {
      final resolver = IconPackResolver(
        _bundleWith({'icons/gba.png': _tinyPng}),
        applyThemeIcons: false,
      );

      final icon = await resolver.resolve('gba');

      // Served by the bundled Default pack instead of the theme's.
      expect(icon.image, isNotNull);
      expect(icon.source, IconPackSource.defaultPack);
      expect(resolver.themeHasIconPack, isTrue);
    });

    test('finds the pack inside a subfolder theme root', () async {
      final resolver = IconPackResolver(_bundleWith({'icons/gba.png': _tinyPng}, prefix: 'My Theme/'));

      expect(resolver.themeHasIconPack, isTrue);
      expect((await resolver.resolve('gba')).source, IconPackSource.theme);
    });
  });
}
