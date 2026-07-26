import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// Builds an in-memory zip from a map of relative path -> file bytes.
Uint8List _buildZip(Map<String, List<int>> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) {
    final data = Uint8List.fromList(bytes);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

List<int> _utf8(String s) => utf8.encode(s);

const _dummyPng = [1, 2, 3, 4]; // bundle only tracks bytes; no real image needed

Map<String, dynamic> _configJson(String name) => {'name': name};

void main() {
  group('OnionThemeBundle.defaultTheme', () {
    test('exposes the Silky config with no zip files', () {
      final bundle = OnionThemeBundle.defaultTheme();

      expect(bundle.config.name, 'Silky');
      expect(bundle.isPack, isFalse);
      expect(bundle['skin/bg-title.png'], isNull);
    });
  });

  group('OnionThemeBundle.fromZipBytes — root detection', () {
    test('theme at the zip root', () {
      final zip = _buildZip({
        'config.json': _utf8(jsonEncode(_configJson('RootTheme'))),
        'skin/bg-title.png': _dummyPng,
      });

      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(bundle.isPack, isFalse);
      expect(bundle.config.name, 'RootTheme');
      expect(bundle['skin/bg-title.png'], _dummyPng);
      expect(bundle['skin/missing.png'], isNull);
    });

    test('theme one directory level down', () {
      final zip = _buildZip({
        'My Theme by Someone/config.json': _utf8(jsonEncode(_configJson('My Theme'))),
        'My Theme by Someone/skin/bg-title.png': _dummyPng,
      });

      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(bundle.isPack, isFalse);
      expect(bundle.config.name, 'My Theme');
      expect(bundle.activeRootPath, 'My Theme by Someone/');
      expect(bundle['skin/bg-title.png'], _dummyPng);
    });

    test('pack with 3 subthemes exposes all roots and defaults to the first', () {
      final zip = _buildZip({
        'preview.png': _dummyPng,
        'Theme A/config.json': _utf8(jsonEncode(_configJson('Theme A'))),
        'Theme A/skin/bg-title.png': _dummyPng,
        'Theme B/config.json': _utf8(jsonEncode(_configJson('Theme B'))),
        'Theme B/skin/bg-title.png': _dummyPng,
        'Theme C/config.json': _utf8(jsonEncode(_configJson('Theme C'))),
        'Theme C/skin/bg-title.png': _dummyPng,
      });

      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(bundle.isPack, isTrue);
      expect(bundle.availableRoots.map((r) => r.displayName), ['Theme A', 'Theme B', 'Theme C']);
      expect(bundle.config.name, 'Theme A');

      final themeB = bundle.withRoot('Theme B/');
      expect(themeB.config.name, 'Theme B');
      expect(themeB.isPack, isTrue); // still knows about its siblings
      expect(themeB['skin/bg-title.png'], _dummyPng);
    });

    test('withRoot throws for an unknown root path', () {
      final zip = _buildZip({
        'config.json': _utf8(jsonEncode(_configJson('Solo'))),
        'skin/bg-title.png': _dummyPng,
      });
      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(() => bundle.withRoot('nope/'), throwsArgumentError);
    });

    test('a theme root with a broken config.json still resolves (defaults)', () {
      final zip = _buildZip({
        'config.json': _utf8('{not valid json'),
        'skin/bg-title.png': _dummyPng,
      });

      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(bundle.config.name, OnionThemeConfig.defaults().name);
      expect(bundle['skin/bg-title.png'], _dummyPng);
    });

    test('__MACOSX and .DS_Store entries are ignored', () {
      final zip = _buildZip({
        '__MACOSX/config.json': _utf8(jsonEncode(_configJson('Junk'))),
        '.DS_Store': _dummyPng,
        'config.json': _utf8(jsonEncode(_configJson('Real'))),
        'skin/bg-title.png': _dummyPng,
        'skin/.DS_Store': _dummyPng,
      });

      final bundle = OnionThemeBundle.fromZipBytes(zip);

      expect(bundle.availableRoots, hasLength(1));
      expect(bundle.config.name, 'Real');
    });
  });

  group('OnionThemeBundle.fromZipBytes — invalid input', () {
    test('zip with no theme throws InvalidThemeZipException', () {
      final zip = _buildZip({'readme.txt': _utf8('just some file')});

      expect(
        () => OnionThemeBundle.fromZipBytes(zip),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });

    test('config.json without a sibling skin/ does not count as a root', () {
      final zip = _buildZip({'config.json': _utf8(jsonEncode(_configJson('NoSkin')))});

      expect(
        () => OnionThemeBundle.fromZipBytes(zip),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });

    test('corrupted / non-zip bytes throw InvalidThemeZipException', () {
      final garbage = Uint8List.fromList(List.generate(64, (i) => i));

      expect(
        () => OnionThemeBundle.fromZipBytes(garbage),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });
  });
}
