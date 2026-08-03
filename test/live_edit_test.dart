import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// The live-edit surface (`OnionThemeBundle.fromFiles`/`withFiles`,
/// `ThemeRenderContext.copyWith`, `OnionPreviewController.applyRenderContext`)
/// exists so an editor can repaint after every keystroke without re-zipping
/// the theme and re-decoding the whole skin. These tests pin that contract.

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

Map<String, Uint8List> _themeFiles({String root = '', String name = 'Test'}) => {
      '${root}config.json': _bytes(jsonEncode({'name': name, 'author': 'Nobody'})),
      '${root}skin/bg-title.png': Uint8List.fromList([1, 2, 3]),
      '${root}skin/background.png': Uint8List.fromList([4, 5, 6]),
    };

/// A 1x1 image, so `copyWith` has something real to carry.
Future<ui.Image> _pixel() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawPaint(ui.Paint()..color = const ui.Color(0xFFFF0000));
  return recorder.endRecording().toImage(1, 1);
}

void main() {
  group('OnionThemeBundle.fromFiles', () {
    test('detects the root and reads files, like fromZipBytes would', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles());

      expect(bundle.config.name, 'Test');
      expect(bundle.activeRootPath, '');
      expect(bundle['skin/bg-title.png'], [1, 2, 3]);
      expect(bundle.isPack, isFalse);
    });

    test('resolves paths against a nested root', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles(root: 'Blueprint by Aemiii91/'));

      expect(bundle.activeRootPath, 'Blueprint by Aemiii91/');
      expect(bundle['skin/bg-title.png'], [1, 2, 3]);
    });

    test('honours activeRootPath on a pack, and falls back to the first root', () {
      final files = {
        ..._themeFiles(root: 'A/', name: 'A'),
        ..._themeFiles(root: 'B/', name: 'B'),
      };

      expect(OnionThemeBundle.fromFiles(files).config.name, 'A');
      expect(OnionThemeBundle.fromFiles(files, activeRootPath: 'B/').config.name, 'B');
      expect(OnionThemeBundle.fromFiles(files, activeRootPath: 'nope/').config.name, 'A');
    });

    test('normalizes separators and drops junk, like the zip path does', () {
      final bundle = OnionThemeBundle.fromFiles({
        '/config.json': _bytes('{"name":"Slashy"}'),
        r'skin\bg-title.png': Uint8List.fromList([9]),
        '__MACOSX/skin/bg-title.png': Uint8List.fromList([0]),
        'skin/.DS_Store': Uint8List.fromList([0]),
      });

      expect(bundle.config.name, 'Slashy');
      expect(bundle['skin/bg-title.png'], [9]);
      expect(bundle.listFiles(), ['config.json', 'skin/bg-title.png']);
    });

    test('throws when there is no theme root', () {
      expect(
        () => OnionThemeBundle.fromFiles({'readme.txt': _bytes('hi')}),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });
  });

  group('OnionThemeBundle.withFiles', () {
    test('overwrites, adds and deletes relative to the active root', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles(root: 'Theme/'));

      final patched = bundle.withFiles({
        'skin/bg-title.png': Uint8List.fromList([7, 7]),
        'skin/pop-bg.png': Uint8List.fromList([8]),
        'skin/background.png': null,
      });

      expect(patched['skin/bg-title.png'], [7, 7]);
      expect(patched['skin/pop-bg.png'], [8]);
      expect(patched['skin/background.png'], isNull);
      expect(patched.activeRootPath, 'Theme/');
      // The original is untouched — patches are copies, so undo is just
      // holding on to the previous bundle.
      expect(bundle['skin/bg-title.png'], [1, 2, 3]);
      expect(bundle['skin/background.png'], [4, 5, 6]);
    });

    test('re-reads config.json when it is the file being patched', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles());
      expect(bundle.config.name, 'Test');

      final patched = bundle.withFiles({
        'config.json': _bytes(jsonEncode({
          'name': 'Renamed',
          'title': {'size': 42}
        })),
      });

      expect(patched.config.name, 'Renamed');
      expect(patched.config.title.size, 42);
      expect(patched.rawConfigJson!['name'], 'Renamed');
    });

    test('keeps the active root of a pack across a patch', () {
      final bundle = OnionThemeBundle.fromFiles(
        {..._themeFiles(root: 'A/', name: 'A'), ..._themeFiles(root: 'B/', name: 'B')},
        activeRootPath: 'B/',
      );

      final patched = bundle.withFiles({
        'skin/bg-title.png': Uint8List.fromList([1])
      });

      expect(patched.activeRootPath, 'B/');
      expect(patched.config.name, 'B');
      expect(patched.isPack, isTrue);
      expect(patched.allFiles.keys, contains('A/config.json'));
    });

    test('an empty patch is a no-op', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles());
      expect(bundle.withFiles(const {}), same(bundle));
    });

    test('throws if the patch removes the last theme root', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles());
      expect(
        () => bundle.withFiles({'config.json': null}),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });
  });

  group('OnionThemeBundle listings', () {
    test('listFiles is root-relative, sorted and prefix-filterable', () {
      final bundle = OnionThemeBundle.fromFiles({
        ..._themeFiles(root: 'Theme/'),
        'Theme/icons/gba.png': Uint8List.fromList([1]),
        'Other/config.json': _bytes('{}'),
      });

      expect(bundle.listFiles(), [
        'config.json',
        'icons/gba.png',
        'skin/background.png',
        'skin/bg-title.png',
      ]);
      expect(bundle.listFiles(underRelativePrefix: 'skin/'),
          ['skin/background.png', 'skin/bg-title.png']);
    });

    test('allFiles spans every root, for writing the theme back out', () {
      final bundle = OnionThemeBundle.fromFiles(
        {..._themeFiles(root: 'A/'), ..._themeFiles(root: 'B/')},
      );

      expect(bundle.allFiles.length, 6);
      expect(() => bundle.allFiles['x'] = Uint8List(0), throwsUnsupportedError);
    });
  });

  group('ThemeRenderContext.copyWith', () {
    test('merges image overrides and keeps everything else', () async {
      final image = await _pixel();
      final base = ThemeRenderContext(
        config: OnionThemeConfig.defaults(),
        images: {ThemeAsset.bgTitle: null, ThemeAsset.background: null},
        fontFamilies: const {'a.ttf': 'FamilyA'},
        assetsFoundInTheme: const {ThemeAsset.bgTitle},
        fontsFailed: const {'broken.ttf'},
        themeHasIconPack: true,
      );

      final patched = base.copyWith(imageOverrides: {ThemeAsset.bgTitle: image});

      expect(patched.image(ThemeAsset.bgTitle), same(image));
      expect(patched.image(ThemeAsset.background), isNull);
      expect(patched.imagesByAsset.length, 2);
      expect(patched.fontFamily('a.ttf'), 'FamilyA');
      expect(patched.assetsFoundInTheme, {ThemeAsset.bgTitle});
      expect(patched.fontsFailed, {'broken.ttf'});
      expect(patched.themeHasIconPack, isTrue);
      // The source context is untouched.
      expect(base.image(ThemeAsset.bgTitle), isNull);
    });

    test('swaps the config without touching images', () async {
      final image = await _pixel();
      final base = ThemeRenderContext(
        config: OnionThemeConfig.defaults(),
        images: {ThemeAsset.bgTitle: image},
        fontFamilies: const {},
      );

      final patched = base.copyWith(
        config: OnionThemeConfig.fromJson(const {
          'name': 'Edited',
          'title': {'size': 12}
        }),
      );

      expect(patched.config.name, 'Edited');
      expect(patched.config.title.size, 12);
      expect(patched.image(ThemeAsset.bgTitle), same(image));
    });
  });

  group('OnionPreviewController.applyRenderContext', () {
    test('swaps the context and notifies, without resolving', () async {
      final controller = OnionPreviewController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final image = await _pixel();
      final theme = OnionThemeBundle.fromFiles(_themeFiles(name: 'Edited'));
      final context = ThemeRenderContext(
        config: theme.config,
        images: {ThemeAsset.bgTitle: image},
        fontFamilies: const {},
      );

      controller.applyRenderContext(context, theme: theme);

      expect(controller.renderContext, same(context));
      expect(controller.theme, same(theme));
      expect(controller.themeLoading, isFalse);
      expect(controller.themeLoadError, isNull);
      expect(notifications, 1);

      // A context is loaded now, so mounting a screen must not kick off a
      // resolution that would overwrite the edit.
      controller.ensureThemeLoaded();
      expect(controller.themeLoading, isFalse);
      expect(controller.renderContext, same(context));
    });

    test('keeps the current theme when none is passed', () async {
      final controller = OnionPreviewController();
      final theme = controller.theme;

      controller.applyRenderContext(ThemeRenderContext(
        config: theme.config,
        images: const {},
        fontFamilies: const {},
      ));

      expect(controller.theme, same(theme));
    });

    test('a load that was already in flight cannot clobber the edit', () async {
      final controller = OnionPreviewController();
      final slow = controller.loadTheme(OnionThemeBundle.defaultTheme());

      final edited = ThemeRenderContext(
        config: OnionThemeConfig.defaults(),
        images: const {},
        fontFamilies: const {},
      );
      controller.applyRenderContext(edited);

      expect(await slow, isFalse);
      expect(controller.renderContext, same(edited));
      expect(controller.themeLoading, isFalse);
    });
  });

  group('bundle equality of edits', () {
    test('withFiles round-trips through fromFiles byte-for-byte', () {
      final bundle = OnionThemeBundle.fromFiles(_themeFiles(root: 'T/'));
      final edited = bundle.withFiles({
        'skin/bg-title.png': Uint8List.fromList([42])
      });

      final reloaded = OnionThemeBundle.fromFiles(edited.allFiles, activeRootPath: 'T/');

      expect(reloaded.allFiles.length, edited.allFiles.length);
      for (final entry in edited.allFiles.entries) {
        expect(listEquals(reloaded.allFiles[entry.key], entry.value), isTrue, reason: entry.key);
      }
    });
  });

  group('allowAssetlessRoot', () {
    Map<String, Uint8List> configOnly({String root = ''}) => {
          '${root}config.json': _bytes(jsonEncode({'name': 'Novo', 'author': 'Eu'})),
        };

    test('a config.json alone is not a theme by default', () {
      // Scanning someone else's zip, a stray config.json in an unrelated
      // directory must not register as a theme.
      expect(
        () => OnionThemeBundle.fromFiles(configOnly()),
        throwsA(isA<InvalidThemeZipException>()),
      );
    });

    test('opted in, a config.json alone is a theme', () {
      // Every asset in the format is optional: a theme that overrides
      // nothing but its config renders as the factory theme, and that is a
      // legitimate starting point for authoring.
      final bundle = OnionThemeBundle.fromFiles(configOnly(), allowAssetlessRoot: true);

      expect(bundle.config.name, 'Novo');
      expect(bundle.activeRootPath, '');
      expect(bundle.isPack, isFalse);
      expect(bundle.listFiles(), ['config.json']);
    });

    test('editing the config of an assetless theme keeps it a theme', () {
      // The reason the flag has to survive: withFiles re-detects roots, so
      // without carrying the flag the first config edit would throw and an
      // empty theme could never be edited at all.
      final bundle = OnionThemeBundle.fromFiles(configOnly(), allowAssetlessRoot: true);

      final edited = bundle.withFiles({
        'config.json': _bytes(jsonEncode({'name': 'Renomeado', 'author': 'Eu'})),
      });

      expect(edited.config.name, 'Renomeado');
    });

    test('the first asset makes it a theme by the strict rule too', () {
      final bundle = OnionThemeBundle.fromFiles(configOnly(), allowAssetlessRoot: true).withFiles({
        'skin/bg-title.png': Uint8List.fromList([1, 2, 3])
      });

      expect(
        OnionThemeBundle.fromFiles(bundle.allFiles).config.name,
        'Novo',
        reason: 'once it has a skin/ file, no opt-in should be needed',
      );
    });

    test('opted in, roots without skin/ are found one level down too', () {
      final bundle = OnionThemeBundle.fromFiles(
        {...configOnly(root: 'Claro/'), ...configOnly(root: 'Escuro/')},
        allowAssetlessRoot: true,
      );

      expect(bundle.isPack, isTrue);
      expect(bundle.availableRoots.map((r) => r.path), ['Claro/', 'Escuro/']);
    });
  });
}
