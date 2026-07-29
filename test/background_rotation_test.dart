import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/core/asset_resolver.dart';

/// The firmware rotates `background.png` 180° at load time
/// (`Onion/src/common/theme/background.h:16` wraps `theme_loadImage` in
/// `rotate180()`), so the package has to as well.
///
/// These tests deliberately use a **vertically asymmetric** background. The
/// golden suite can't cover this: every golden renders the bundled Silky,
/// whose background is a single flat colour and therefore pixel-identical
/// under a 180° rotation. That blind spot is exactly why the bug shipped.
Uint8List _buildZip(Map<String, List<int>> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) {
    final data = Uint8List.fromList(bytes);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// Encodes a [width]x[height] PNG whose top half is [top] and bottom half
/// is [bottom], so a 180° rotation is observable.
Future<Uint8List> _halvesPng({
  required int width,
  required int height,
  required ui.Color top,
  required ui.Color bottom,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final half = height / 2;
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), half), ui.Paint()..color = top);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, half, width.toDouble(), half),
    ui.Paint()..color = bottom,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// The colour at a single pixel of [image].
Future<ui.Color> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData();
  final offset = (y * image.width + x) * 4;
  final bytes = data!.buffer.asUint8List();
  return ui.Color.fromARGB(
    bytes[offset + 3],
    bytes[offset],
    bytes[offset + 1],
    bytes[offset + 2],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const red = ui.Color(0xFFFF0000);
  const blue = ui.Color(0xFF0000FF);

  Future<OnionThemeBundle> bundleWithBackground(Uint8List png) async {
    return OnionThemeBundle.fromZipBytes(_buildZip({
      'config.json': utf8.encode('{"name":"Rotation test"}'),
      'skin/background.png': png,
    }));
  }

  group('background rotation', () {
    test('a theme background is rotated 180° on resolve', () async {
      final png = await _halvesPng(width: 640, height: 480, top: red, bottom: blue);
      final resolver = AssetResolver(await bundleWithBackground(png));

      final image = await resolver.resolve(ThemeAsset.background);

      expect(image, isNotNull);
      expect(image!.width, 640);
      expect(image.height, 480);
      // Authored red-on-top must come back blue-on-top.
      expect(await _pixelAt(image, 320, 10), blue);
      expect(await _pixelAt(image, 320, 470), red);
    });

    test('rotation is horizontal as well as vertical', () async {
      // A single marked corner pins both axes: a vertical-only flip would
      // leave it on the left, a true 180° rotation moves it to the right.
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 640, 480), ui.Paint()..color = blue);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 32, 32), ui.Paint()..color = red);
      final picture = recorder.endRecording();
      final marked = await picture.toImage(640, 480);
      picture.dispose();
      final png = (await marked.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      marked.dispose();

      final resolver = AssetResolver(await bundleWithBackground(png));
      final image = (await resolver.resolve(ThemeAsset.background))!;

      expect(await _pixelAt(image, 623, 463), red, reason: 'marker should land bottom-right');
      expect(await _pixelAt(image, 16, 16), blue, reason: 'top-left should be cleared');
    });

    test('non-square backgrounds keep their dimensions', () async {
      // Real themes ship these: Zelda Oracle is 646x478, StarOnion64 1200x900.
      final png = await _halvesPng(width: 646, height: 478, top: red, bottom: blue);
      final resolver = AssetResolver(await bundleWithBackground(png));

      final image = (await resolver.resolve(ThemeAsset.background))!;

      expect(image.width, 646);
      expect(image.height, 478);
      expect(await _pixelAt(image, 323, 8), blue);
    });

    test('other assets are not rotated', () async {
      final png = await _halvesPng(width: 640, height: 60, top: red, bottom: blue);
      final bundle = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Rotation test"}'),
        'skin/bg-title.png': png,
      }));
      final resolver = AssetResolver(bundle);

      final image = (await resolver.resolve(ThemeAsset.bgTitle))!;

      // `rotate180` appears only in the firmware's background.h.
      expect(await _pixelAt(image, 320, 5), red);
      expect(await _pixelAt(image, 320, 55), blue);
    });

    test('the flat default background is unchanged by rotation', () async {
      // Documents why the goldens stayed green through this fix: Silky's
      // background is one flat colour, so rotating it is a no-op.
      final resolver = AssetResolver(OnionThemeBundle.defaultTheme());

      final image = (await resolver.resolve(ThemeAsset.background))!;

      final topLeft = await _pixelAt(image, 0, 0);
      final bottomRight = await _pixelAt(image, image.width - 1, image.height - 1);
      final middle = await _pixelAt(image, image.width ~/ 2, image.height ~/ 2);
      expect(topLeft, middle);
      expect(bottomRight, middle);
    });

    test('the rotated image is cached, not recomputed', () async {
      final png = await _halvesPng(width: 640, height: 480, top: red, bottom: blue);
      final resolver = AssetResolver(await bundleWithBackground(png));

      final first = await resolver.resolve(ThemeAsset.background);
      final second = await resolver.resolve(ThemeAsset.background);

      expect(identical(first, second), isTrue);
    });
  });
}
