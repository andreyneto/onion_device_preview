// Compara renders contra as capturas nativas do device em
// test/fixtures/device/ (ver o README de lá). Diferente dos goldens, que
// congelam o que NÓS desenhamos, isto ancora o render no hardware real —
// um golden regenerado sem querer passa; isto não.
//
// Precisa da Silky do repo Themes/ (o tema das capturas), então é pulado
// quando o checkout irmão não está presente.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

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

/// Erro absoluto médio por canal entre duas imagens 640x480 RGBA, sobre a
/// região [rect] (a imagem toda quando omitida).
double _mae(Uint8List a, Uint8List b, {Rect? rect}) {
  final r = rect ?? const Rect.fromLTWH(0, 0, 640, 480);
  var sum = 0;
  var count = 0;
  for (var y = r.top.toInt(); y < r.bottom.toInt(); y++) {
    for (var x = r.left.toInt(); x < r.right.toInt(); x++) {
      final i = (y * 640 + x) * 4;
      for (var c = 0; c < 3; c++) {
        sum += (a[i + c] - b[i + c]).abs();
        count++;
      }
    }
  }
  return sum / count;
}

Future<Uint8List> _rgbaOf(File file) async {
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('the Game Switcher matches the device captures', (tester) async {
    final themeDir = Directory('${Directory.current.path}/../Themes/themes/Silky by DiMo');
    if (!themeDir.existsSync()) {
      markTestSkipped('../Themes not checked out');
      return;
    }

    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();

    await tester.runAsync(() async {
      final exo = FontLoader('packages/onion_device_preview/Exo 2 Bold Italic')
        ..addFont(rootBundle.load('packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf'));
      await exo.load();

      // 95% e wifi desligado: o estado em que as capturas foram tiradas.
      final controller = OnionPreviewController()
        ..setBatteryPercent(95)
        ..setWifi(OnionWifiState.off)
        ..resetTo(OnionScreenKind.mainMenu);
      expect(await controller.loadTheme(OnionThemeBundle.fromZipBytes(_zipDirectory(themeDir))), isTrue);

      controller.openGameSwitcher();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
          ),
        ),
      );

      Future<Uint8List> render() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await tester.pump();
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      }

      // Histórico vazio: sem screenshot de jogo por baixo, então tudo na
      // tela é chrome do tema e a comparação é direta. Mediu 0.48.
      controller.setGsHistoryEmpty(true);
      final empty = await render();
      final emptyDevice = await _rgbaOf(File('test/fixtures/device/dev_gs_empty.png'));
      expect(
        _mae(empty, emptyDevice),
        lessThan(2.0),
        reason: 'switcher vazio deve casar com o device (resíduo é só rasterização de texto)',
      );
      // A arte `Empty` centrada bate exatamente; o corpo não tolera desvio.
      expect(_mae(empty, emptyDevice, rect: const Rect.fromLTWH(0, 40, 640, 400)), lessThan(0.5));
      // As barras do tema são blit puro: pixel-perfect.
      expect(_mae(empty, emptyDevice, rect: const Rect.fromLTWH(0, 440, 640, 40)), lessThan(0.01));
      controller.setGsHistoryEmpty(false);

      // Dialog: só o painel, porque fora dele fica o screenshot sintético
      // do mock, que não tem como casar com o do device.
      controller.showDialog(
        title: 'Remove from history',
        message: 'Are you sure you want to\nremove game from history?',
        showHint: true,
      );
      final dialog = await render();
      final dialogDevice = await _rgbaOf(File('test/fixtures/device/dev_gs_dialog.png'));
      expect(
        _mae(dialog, dialogDevice, rect: const Rect.fromLTWH(40, 85, 560, 300)),
        lessThan(6.0),
        reason: 'conteúdo do dialog deve casar com o device',
      );

      controller.dispose();
    });
  });
}
