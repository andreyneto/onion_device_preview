import 'dart:convert';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// Regression for the two things that broke "Aubergine by blueasis" — a
/// theme that ships `hint.size: 0` and a full-screen `Empty.png`:
///
///  - the dialog title was styled with `total` (whose size falls back to
///    `hint`, i.e. 0 here), so it disappeared. `dialog.h:45` renders it
///    with `resource_getFont(TITLE)` and only takes `total.color`.
///  - an empty rom list scaled `Empty.png` down to fit the 640x360 body
///    band. The firmware blits it at native size, and it's layer 15 of
///    the Roms stack (`docs/guide.txt`) — above the header and footer.
///
/// 15 of the 249 themes in the sibling `Themes/` checkout resolve
/// `total.size` to 0; 145 more resolve it to something other than
/// `title.size`.
void main() {
  Uint8List themeZip(Uint8List solidMagentaPng) {
    final config = {
      'name': 'ZeroHint',
      'title': {'size': 30, 'color': '#FFFFFF'},
      // No `size` on hint -> 0 propagates into currentpage/total, exactly
      // like Aubergine's `"hint": {"size": 0}`.
      'hint': {'size': 0, 'color': '#FFFFFF'},
      'currentpage': {'color': '#FFFFFF'},
      'total': {'color': '#FFFFFF'},
    };
    final archive = Archive()
      ..addFile(ArchiveFile.string('config.json', jsonEncode(config)))
      ..addFile(ArchiveFile('skin/Empty.png', solidMagentaPng.length, solidMagentaPng));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  Future<ByteData> render(WidgetTester tester, void Function(OnionPreviewController) scene) async {
    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late ByteData pixels;
    await tester.runAsync(() async {
      await (FontLoader(kOnionFallbackFontFamily)
            ..addFont(rootBundle.load(
                'packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf')))
          .load();

      // Image encoding is real async work, so it has to happen in here.
      final emptyArt = await _encodeSolidPng(640, 480, const Color(0xFFFF00FF));

      final controller = OnionPreviewController();
      addTearDown(controller.dispose);
      await controller.loadTheme(OnionThemeBundle.fromZipBytes(themeZip(emptyArt)));
      scene(controller);

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
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await tester.pump();

      final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    return pixels;
  }

  testWidgets('a dialog title still renders when total.size falls back to 0', (tester) async {
    final pixels = await render(tester, (c) {
      c.resetTo(OnionScreenKind.mainMenu);
      c.showDialog(title: 'MMMMMMMM', message: '');
    });

    // `dialog.h:44` centers the title on `pop.y + 25`; pop-bg comes from
    // the default skin (640x330 -> top y=75), so the 30px title straddles
    // y=100 around the horizontal center.
    expect(
      _hasPixelsMatching(pixels, const Rect.fromLTWH(200, 88, 240, 24), const Color(0xFFFFFFFF)),
      isTrue,
      reason: 'the dialog title must use title.size, not total.size',
    );
  });

  testWidgets('an empty rom list blits Empty.png at native size over the chrome', (tester) async {
    final pixels = await render(tester, (c) {
      c.resetTo(OnionScreenKind.mainMenu);
      c.openGameList(const [], 'GBA');
    });

    // The art is 640x480: scaled into the 640x360 body band it would be
    // 480x360 at x=80..560, y=60..420, leaving the corners untouched.
    for (final corner in const [Offset(4, 4), Offset(636, 4), Offset(4, 476), Offset(636, 476)]) {
      expect(
        _hasPixelsMatching(pixels, Rect.fromLTWH(corner.dx - 2, corner.dy - 2, 4, 4), const Color(0xFFFF00FF)),
        isTrue,
        reason: 'Empty.png must cover the full 640x480 screen at $corner',
      );
    }
  });
}

/// Whether any pixel inside [area] of a 640-wide rawRgba buffer is exactly
/// [color] (ignoring alpha).
bool _hasPixelsMatching(ByteData pixels, Rect area, Color color) {
  for (var y = area.top.toInt(); y < area.bottom.toInt(); y++) {
    for (var x = area.left.toInt(); x < area.right.toInt(); x++) {
      final i = (y * 640 + x) * 4;
      if (pixels.getUint8(i) == (color.r * 255).round() &&
          pixels.getUint8(i + 1) == (color.g * 255).round() &&
          pixels.getUint8(i + 2) == (color.b * 255).round()) {
        return true;
      }
    }
  }
  return false;
}

Future<Uint8List> _encodeSolidPng(int width, int height, Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
