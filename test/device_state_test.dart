import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

void main() {
  group('OnionPreviewController — navigation stack', () {
    test('starts at boot and goTo pushes onto the stack', () {
      final controller = OnionPreviewController();

      expect(controller.currentScreen, OnionScreenKind.boot);

      controller.goTo(OnionScreenKind.mainMenu);
      controller.goTo(OnionScreenKind.gameList);

      expect(controller.currentScreen, OnionScreenKind.gameList);
      expect(controller.navigationStack, [OnionScreenKind.boot, OnionScreenKind.mainMenu, OnionScreenKind.gameList]);
    });

    test('goBack pops, and is a no-op at the root', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.mainMenu);

      controller.goBack();
      expect(controller.currentScreen, OnionScreenKind.boot);

      controller.goBack();
      expect(controller.currentScreen, OnionScreenKind.boot);
    });

    test('resetTo replaces the entire stack', () {
      final controller = OnionPreviewController()
        ..goTo(OnionScreenKind.mainMenu)
        ..goTo(OnionScreenKind.gameList)
        ..resetTo(OnionScreenKind.shutdown);

      expect(controller.navigationStack, [OnionScreenKind.shutdown]);
    });

    test('notifies listeners on navigation', () {
      final controller = OnionPreviewController();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.goTo(OnionScreenKind.mainMenu);
      controller.goBack();

      expect(notified, 2);
    });
  });

  group('OnionPreviewController — battery / charging / wifi / expert / clock', () {
    test('battery percent clamps to 0..100', () {
      final controller = OnionPreviewController();

      controller.setBatteryPercent(150);
      expect(controller.batteryPercent, 100);

      controller.setBatteryPercent(-10);
      expect(controller.batteryPercent, 0);
    });

    test('charging, wifi, expert mode and clock round-trip', () {
      final controller = OnionPreviewController();

      controller.setCharging(true);
      expect(controller.charging, isTrue);

      controller.setWifi(OnionWifiState.locked);
      expect(controller.wifi, OnionWifiState.locked);

      controller.setExpertMode(true);
      expect(controller.expertMode, isTrue);

      controller.setClock(9, 5);
      expect(controller.clockText, '09:05');
    });

    test('clock hour/minute clamp to valid ranges', () {
      final controller = OnionPreviewController();

      controller.setClock(30, 90);

      expect(controller.clockText, '23:59');
    });
  });

  group('OnionPreviewController — per-screen selection cursors', () {
    test('moveDown wraps using the registered item count', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.gameList);
      controller.setItemCount(OnionScreenKind.gameList, 3);

      expect(controller.selectionFor(OnionScreenKind.gameList), 0);

      controller.moveDown();
      controller.moveDown();
      expect(controller.selectionFor(OnionScreenKind.gameList), 2);

      controller.moveDown();
      expect(controller.selectionFor(OnionScreenKind.gameList), 0); // wraps
    });

    test('moveUp wraps backwards past zero', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.gameList);
      controller.setItemCount(OnionScreenKind.gameList, 3);

      controller.moveUp();

      expect(controller.selectionFor(OnionScreenKind.gameList), 2);
    });

    test('moving with an unset (zero) item count is a no-op', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.mainMenu);

      controller.moveDown();

      expect(controller.selectionFor(OnionScreenKind.mainMenu), 0);
    });

    test('horizontal cursor (moveLeft/moveRight) is independent of the vertical one', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.mainMenu);
      controller.setItemCount(OnionScreenKind.mainMenu, 10);
      controller.setColumnCount(OnionScreenKind.mainMenu, 6);

      controller.moveDown();
      controller.moveRight();
      controller.moveRight();

      expect(controller.selectionFor(OnionScreenKind.mainMenu), 1);
      expect(controller.horizontalFor(OnionScreenKind.mainMenu), 2);
    });

    test('shrinking the item count clamps an out-of-range selection', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.gameList);
      controller.setItemCount(OnionScreenKind.gameList, 5);
      controller.moveUp(); // selection = 4

      controller.setItemCount(OnionScreenKind.gameList, 2);

      expect(controller.selectionFor(OnionScreenKind.gameList), 1);
    });

    test('selection cursors are independent per screen', () {
      final controller = OnionPreviewController();
      controller.setItemCount(OnionScreenKind.gameList, 5);
      controller.setItemCount(OnionScreenKind.gameSystems, 5);

      controller.goTo(OnionScreenKind.gameList);
      controller.moveDown();
      controller.goTo(OnionScreenKind.gameSystems);
      controller.moveDown();
      controller.moveDown();

      expect(controller.selectionFor(OnionScreenKind.gameList), 1);
      expect(controller.selectionFor(OnionScreenKind.gameSystems), 2);
    });
  });

  group('OnionPreviewController — semantic button actions', () {
    test('pressB defaults to goBack when onCancel is unset', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.mainMenu);

      controller.pressB();

      expect(controller.currentScreen, OnionScreenKind.boot);
    });

    test('pressB calls the current screen\'s onCancel instead of goBack when set', () {
      final controller = OnionPreviewController()..goTo(OnionScreenKind.mainMenu);
      var cancelled = false;
      controller.bindScreenHandlers(OnionScreenKind.mainMenu, onCancel: () => cancelled = true);

      controller.pressB();

      expect(cancelled, isTrue);
      expect(controller.currentScreen, OnionScreenKind.mainMenu); // stack untouched
    });

    test('pressA/Start/Select/Menu dispatch to the current screen\'s handlers', () {
      final controller = OnionPreviewController(); // starts at boot
      final calls = <String>[];
      controller.bindScreenHandlers(
        OnionScreenKind.boot,
        onConfirm: () => calls.add('a'),
        onStart: () => calls.add('start'),
        onSelect: () => calls.add('select'),
      );
      controller.onMenu = () {
        calls.add('menu');
      };

      controller.pressA();
      controller.pressStart();
      controller.pressSelect();
      controller.pressMenu();

      expect(calls, ['a', 'start', 'select', 'menu']);
    });

    test('a disposing screen cannot clobber its successor\'s handlers', () {
      // Regression: during a base-screen swap the NEW screen's initState
      // runs before the OLD screen's dispose (Flutter finalizes outgoing
      // elements at end of frame). With a single mutable callback slot,
      // boot's dispose used to null out the handler the main menu had
      // just registered — per-screen keying makes that impossible.
      final controller = OnionPreviewController();
      var advanced = false;
      var activated = false;
      controller.bindScreenHandlers(OnionScreenKind.boot, onConfirm: () => advanced = true);

      controller.resetTo(OnionScreenKind.mainMenu);
      controller.bindScreenHandlers(OnionScreenKind.mainMenu, onConfirm: () => activated = true);
      controller.unbindScreenHandlers(OnionScreenKind.boot); // boot's late dispose

      controller.pressA();

      expect(activated, isTrue);
      expect(advanced, isFalse);
    });

    test('an overlay shadows the base screen\'s handlers and restores them on close', () {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.gameList);
      final calls = <String>[];
      controller.bindScreenHandlers(OnionScreenKind.gameList, onConfirm: () => calls.add('launch'));

      controller.showDialog(title: 'T', message: 'M', showHint: true);
      controller.bindScreenHandlers(OnionScreenKind.dialog, onConfirm: () => calls.add('dialog-ok'));
      controller.pressA();

      controller.goBack(); // dialog closes...
      controller.unbindScreenHandlers(OnionScreenKind.dialog); // ...and disposes
      controller.pressA();

      expect(calls, ['dialog-ok', 'launch']);
    });

    test('pressA/Start/Select/Menu are safe no-ops when unset', () {
      final controller = OnionPreviewController();

      expect(() {
        controller.pressA();
        controller.pressStart();
        controller.pressSelect();
        controller.pressMenu();
      }, returnsNormally);
    });
  });

  group('OnionPreviewController — loadTheme pipeline (T5.2)', () {
    // These exercise real engine async work (rootBundle + image decode),
    // so the binding must be up. Plain test() bodies run in real async —
    // no FakeAsync pitfalls here.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('ensureThemeLoaded resolves the initial theme exactly once', () async {
      final controller = OnionPreviewController();
      expect(controller.renderContext, isNull);

      controller.ensureThemeLoaded();
      final loading = controller.themeLoading;
      controller.ensureThemeLoaded(); // no-op while in flight

      // Poll until the load lands (no public future for the initial kick).
      while (controller.renderContext == null) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(loading, isTrue);
      expect(controller.themeLoading, isFalse);
      expect(controller.themeLoadError, isNull);
      expect(controller.renderContext!.config.name, 'Silky');
    });

    test('loadTheme swaps theme and render context atomically on success', () async {
      final controller = OnionPreviewController();
      final bundle = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Swapped"}'),
        'skin/background.png': _tinyPng,
      }));

      final swapped = await controller.loadTheme(bundle);

      expect(swapped, isTrue);
      expect(identical(controller.theme, bundle), isTrue);
      expect(controller.renderContext!.config.name, 'Swapped');
      expect(controller.renderContext!.assetsFoundInTheme, contains(ThemeAsset.background));
      expect(controller.themeLoadError, isNull);
    });

    test('a corrupt PNG in the zip falls back to the default skin instead of failing the load', () async {
      final controller = OnionPreviewController();
      final bundle = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Broken"}'),
        'skin/bg-title.png': utf8.encode('not a png'),
      }));

      final swapped = await controller.loadTheme(bundle);

      expect(swapped, isTrue);
      expect(controller.themeLoadError, isNull);
      expect(controller.renderContext!.assetsFoundInTheme, isNot(contains(ThemeAsset.bgTitle)));
      expect(controller.renderContext!.assetsFromDefaultSkin, contains(ThemeAsset.bgTitle));
    });

    test('a superseding loadTheme wins over one still in flight', () async {
      final controller = OnionPreviewController();
      final first = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"First"}'),
        'skin/background.png': _tinyPng,
      }));
      final second = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Second"}'),
        'skin/background.png': _tinyPng,
      }));

      final results = await Future.wait([controller.loadTheme(first), controller.loadTheme(second)]);

      expect(results[0], isFalse, reason: 'the superseded load must not swap');
      expect(results[1], isTrue);
      expect(controller.renderContext!.config.name, 'Second');
    });

    test('rawConfigJson exposes what the theme itself set (for ThemeInspector)', () {
      final bundle = OnionThemeBundle.fromZipBytes(_buildZip({
        'config.json': utf8.encode('{"name":"Raw","title":{"size":30}}'),
        'skin/background.png': _tinyPng,
      }));

      expect(bundle.rawConfigJson!['name'], 'Raw');
      expect((bundle.rawConfigJson!['title'] as Map<String, dynamic>)['size'], 30);
      expect(bundle.rawConfigJson!.containsKey('hint'), isFalse);
    });
  });
}

/// A valid, decodable 1x1 red-pixel PNG (same bytes as
/// asset_resolver_test.dart) so loads exercise real decoding.
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
