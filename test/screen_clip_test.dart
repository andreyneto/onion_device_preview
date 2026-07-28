import 'dart:convert';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// Regression for "AnalogPhosphor Tight by trash" and "Scallion by
/// Cyberbellum": both ship `icon-A-54`/`icon-B-54` as **640x54 fully
/// transparent** canvases, so `footer.h:31`'s `offsetX += icon->w + 5`
/// puts the `SELECT` label at x=665. On the device that's off the
/// framebuffer and `SDL_BlitSurface` drops it — the intended look, and
/// what both themes' own `preview.png` shows. In the preview it used to
/// paint outside the 640x480 screen, over the device shell's bezel.
///
/// The screen must clip like the framebuffer does, for the same reason
/// win98's 982x900 battery canvas (spec §11.1) has to stay inside.
void main() {
  const margin = Color(0xFF00FF00);

  testWidgets('nothing the screen paints escapes its 640x480 bounds', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late ByteData pixels;
    await tester.runAsync(() async {
      await (FontLoader(kOnionFallbackFontFamily)
            ..addFont(rootBundle.load(
                'packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf')))
          .load();

      // A 640-wide transparent button canvas, exactly like both themes'.
      final wideButton = await _encodePng(640, 54, const Color(0x00000000));
      final config = {
        'name': 'WideButtons',
        'title': {'size': 20, 'color': '#FFFFFF'},
        'hint': {'size': 18, 'color': '#FFFFFF'},
      };
      final archive = Archive()
        ..addFile(ArchiveFile.string('config.json', jsonEncode(config)))
        ..addFile(ArchiveFile('skin/icon-A-54.png', wideButton.length, wideButton))
        ..addFile(ArchiveFile('skin/icon-B-54.png', wideButton.length, wideButton));

      final controller = OnionPreviewController()..resetTo(OnionScreenKind.settingsList);
      addTearDown(controller.dispose);
      await controller.loadTheme(
        OnionThemeBundle.fromZipBytes(Uint8List.fromList(ZipEncoder().encode(archive)!)),
      );

      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              width: 900,
              height: 700,
              color: margin,
              alignment: Alignment.topLeft,
              child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await tester.pump();

      final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    final escaped = <String>[];
    for (var y = 0; y < 700; y++) {
      for (var x = 0; x < 900; x++) {
        if (x < 640 && y < 480) continue;
        final i = (y * 900 + x) * 4;
        final r = pixels.getUint8(i);
        final g = pixels.getUint8(i + 1);
        final b = pixels.getUint8(i + 2);
        if (r != 0 || g != 255 || b != 0) {
          escaped.add('($x,$y)=#${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
        }
      }
    }

    expect(
      escaped,
      isEmpty,
      reason: 'the screen painted ${escaped.length} pixels outside 640x480, e.g. ${escaped.take(5).join(', ')}',
    );
  });
}

Future<Uint8List> _encodePng(int width, int height, Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
