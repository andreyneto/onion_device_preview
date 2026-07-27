import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// T6.1 — golden tests of the calibrated screens with the bundled
/// default (Silky) skin, freezing the 1:1 work verified against the
/// stock preview and real-device screenshots (docs/spec-1a1.md §10/§11).
/// Regenerate deliberately with `flutter test --update-goldens`.
///
/// Fonts are registered under the exact families production resolves
/// (the packages/-prefixed Exo 2, and Roboto for the .ttc fallback), so
/// text renders with real glyphs instead of the Ahem placeholder.
void main() {
  testWidgets('screens match their goldens with the default skin', (tester) async {
    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = OnionPreviewController()
      ..setBatteryPercent(97)
      ..setWifi(OnionWifiState.signal2);

    // Real async work (font/image decoding, async icon loads) must run
    // inside runAsync — but matchesGoldenFile calls runAsync itself, so
    // each screen is staged in its own runAsync block and captured
    // outside it.
    Future<void> stage(Future<void> Function()? mutate) async {
      await tester.runAsync(() async {
        await mutate?.call();
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 700));
      });
      await tester.pump();
    }

    await stage(() async {
      final exo = FontLoader('packages/onion_device_preview/Exo 2 Bold Italic')
        ..addFont(rootBundle.load('packages/onion_device_preview/assets/default_skin/fonts/Exo-2-Bold-Italic.ttf'));
      await exo.load();
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      if (flutterRoot != null) {
        final robotoFile = File('$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
        if (robotoFile.existsSync()) {
          final bytes = robotoFile.readAsBytesSync();
          final roboto = FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)));
          await roboto.load();
        }
      }

      await controller.loadTheme(OnionThemeBundle.defaultTheme());

      await tester.pumpWidget(
        RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
          ),
        ),
      );
    });

    final screen = find.byType(RepaintBoundary).first;

    await stage(() async => controller.resetTo(OnionScreenKind.mainMenu));
    await expectLater(screen, matchesGoldenFile('goldens/main_menu.png'));

    await stage(() async => controller.goTo(OnionScreenKind.gameSystems));
    await expectLater(screen, matchesGoldenFile('goldens/game_systems.png'));

    final arcade = OnionMockData.gameSystems.last;
    await stage(() async {
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openGameList(arcade.roms, arcade.name);
    });
    await expectLater(screen, matchesGoldenFile('goldens/game_list.png'));

    await stage(() async => controller.showPopMenu(const ['Launch', 'Clear list'], onSelect: (_) {}));
    await expectLater(screen, matchesGoldenFile('goldens/pop_menu.png'));

    await stage(() async {
      controller.goBack();
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openSettingsTree(OnionMockData.settings, 'Settings');
    });
    await expectLater(screen, matchesGoldenFile('goldens/settings.png'));

    await stage(() async =>
        controller.showDialog(title: 'Confirmação', message: 'Um diálogo de exemplo.', showHint: true));
    await expectLater(screen, matchesGoldenFile('goldens/dialog.png'));

    // Apps: tall bg-list-l rows with icon-pack icons (icons/app/<name>),
    // served here by the bundled Default pack.
    await stage(() async {
      controller.goBack();
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openSettingsTree(
        [
          for (final app in OnionMockData.apps)
            OnionMockSimpleItem(app.name, large: true, iconPackName: app.iconName),
        ],
        'Apps',
      );
    });
    await expectLater(screen, matchesGoldenFile('goldens/apps.png'));
  });
}
