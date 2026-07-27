import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/core/font_loader.dart';

Uint8List _buildZip(Map<String, List<int>> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) {
    final data = Uint8List.fromList(bytes);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnionFontResolver — system fonts (absolute paths)', () {
    test('maps a known system font filename to its bundled, package-prefixed family', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic.ttf');

      // Package-pubspec fonts only resolve in a consuming app under the
      // packages/ prefix — the bare family silently renders as Roboto.
      expect(family, 'packages/onion_device_preview/Exo 2 Bold Italic');
      expect(resolver.failed, isEmpty);
    });

    test('the _Universal variant (what stock Silky references) maps to the same family', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic_Universal.ttf');

      expect(family, 'packages/onion_device_preview/Exo 2 Bold Italic');
      expect(resolver.failed, isEmpty);
    });

    test('an unbundled system font falls back', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('/mnt/SDCARD/miyoo/app/MicrosoftYaHeiGB.ttf');

      expect(family, kOnionFallbackFontFamily);
      expect(resolver.failed, contains('/mnt/SDCARD/miyoo/app/MicrosoftYaHeiGB.ttf'));
    });

    test('HENB.TTF — the most referenced system font — resolves to its own family', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('/mnt/SDCARD/miyoo/app/HENB.TTF');

      // Not the Exo 2 fallback: 23 of the 202 real themes ask for this face.
      expect(family, 'packages/onion_device_preview/Helvetica Neue Bold');
      expect(resolver.failed, isEmpty);
    });

    test('wqy-microhei.ttc registers the real face lazily instead of standing in Roboto', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('/mnt/SDCARD/miyoo/app/wqy-microhei.ttc');

      expect(family, isNot(kOnionTtcFallbackFontFamily));
      expect(family, 'onion-system-wqy-microhei.ttc');
      expect(resolver.failed, isEmpty);
    });

    test('the lazily registered face is shared across resolver instances', () async {
      final a = OnionFontResolver(OnionThemeBundle.defaultTheme());
      final b = OnionFontResolver(OnionThemeBundle.defaultTheme());

      // Unlike theme-provided fonts (namespaced per instance), a system
      // font is the package's own file — same bytes, so same family.
      expect(
        await a.resolveFamily('/mnt/SDCARD/miyoo/app/wqy-microhei.ttc'),
        await b.resolveFamily('/mnt/SDCARD/miyoo/app/wqy-microhei.ttc'),
      );
    });
  });

  group('OnionFontResolver — theme-provided fonts', () {
    test('a relative .ttc missing from the zip falls back like any missing font', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      // Nothing special about the container format here: the zip simply
      // doesn't carry this file.
      expect(await resolver.resolveFamily('wqy-microhei.ttc'), kOnionFallbackFontFamily);
      expect(resolver.failed, contains('wqy-microhei.ttc'));
    });

    test('a relative path missing from the zip falls back', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final family = await resolver.resolveFamily('DoesNotExist.ttf');

      expect(family, kOnionFallbackFontFamily);
      expect(resolver.failed, contains('DoesNotExist.ttf'));
    });

    test('a real font shipped in the zip loads under a unique family name', () async {
      final fontBytes = (await rootBundle.load(
        'packages/onion_device_preview/assets/default_skin/fonts/BPreplayBold.otf',
      ))
          .buffer
          .asUint8List();

      final bundle = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Test"}'),
        'skin/dummy.png': [0],
        'CustomFont.otf': fontBytes,
      }));
      final resolver = OnionFontResolver(bundle);

      final family = await resolver.resolveFamily('CustomFont.otf');

      expect(family, isNot(kOnionFallbackFontFamily));
      expect(resolver.failed, isEmpty);
    });

    test('resolving the same path twice returns the cached family', () async {
      final resolver = OnionFontResolver(OnionThemeBundle.defaultTheme());

      final first = await resolver.resolveFamily('DoesNotExist.ttf');
      final second = await resolver.resolveFamily('DoesNotExist.ttf');

      expect(first, second);
    });

    test('two resolver instances never produce the same family name for the same path', () async {
      final fontBytes = (await rootBundle.load(
        'packages/onion_device_preview/assets/default_skin/fonts/BPreplayBold.otf',
      ))
          .buffer
          .asUint8List();

      OnionThemeBundle bundleWith(String path) => OnionThemeBundle.fromZipBytes(_buildZip({
            'config.json': utf8.encode('{"name":"Test"}'),
            'skin/dummy.png': [0],
            path: fontBytes,
          }));

      final familyA = await OnionFontResolver(bundleWith('CustomFont.otf')).resolveFamily('CustomFont.otf');
      final familyB = await OnionFontResolver(bundleWith('CustomFont.otf')).resolveFamily('CustomFont.otf');

      expect(familyA, isNot(familyB));
    });
  });
}
