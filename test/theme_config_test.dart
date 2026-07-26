import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

void main() {
  group('OnionThemeConfig.defaults', () {
    test('matches firmware hardcoded defaults', () {
      final config = OnionThemeConfig.defaults();

      expect(config.name, '');
      expect(config.title.font, kOnionFallbackFontPath);
      expect(config.title.size, 36);
      expect(config.title.color, const Color(0xFFFFFFFF));
      expect(config.hint.size, 40);
      expect(config.list.size, 24);
      expect(config.grid.font, kOnionFallbackFontPath);
      expect(config.grid.grid1x4, 24);
      expect(config.grid.grid3x4, 18);
      expect(config.grid.color, const Color(0xFF686868));
      expect(config.batteryPercentage.visible, isFalse);
      expect(config.batteryPercentage.textAlign, OnionTextAlign.left);
      expect(config.frame.borderLeft, 0);
      expect(config.hideLabels.icons, isFalse);
    });
  });

  group('OnionThemeConfig.fromJson — empty/minimal config', () {
    test('{} resolves to the same values as .defaults()', () {
      final config = OnionThemeConfig.fromJson(const {});
      final defaults = OnionThemeConfig.defaults();

      expect(config.title.font, defaults.title.font);
      expect(config.title.size, defaults.title.size);
      // Firmware quirk (config.h:135): with no `hint` in the json, size
      // unconditionally inherits from the *resolved* title, even though
      // hint's own static default is 40 — title's fallback param is null,
      // so title always keeps its own default (36), and that's what hint
      // then inherits.
      expect(config.hint.size, defaults.title.size);
      expect(config.currentpage.font, defaults.hint.font);
      expect(config.currentpage.color, defaults.hint.color);
      expect(config.grid.color, defaults.grid.color);
      expect(config.batteryPercentage.font, defaults.hint.font);
    });

    test('win98-style minimal battery ({visible: false}) keeps other battery defaults', () {
      final config = OnionThemeConfig.fromJson(const {
        'batteryPercentage': {'visible': false},
      });

      expect(config.batteryPercentage.visible, isFalse);
      expect(config.batteryPercentage.size, 24);
      expect(config.batteryPercentage.textAlign, OnionTextAlign.left);
    });
  });

  group('OnionThemeConfig.fromJson — fallback chains', () {
    test('hint falls back to title font/size/color when unset', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'font': 'Custom.ttf', 'size': 50, 'color': '#112233'},
      });

      expect(config.hint.font, 'Custom.ttf');
      expect(config.hint.size, 50);
      expect(config.hint.color, const Color(0xFF112233));
    });

    test('currentpage/total fall back to hint (not title) when unset', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'font': 'Title.ttf', 'size': 10, 'color': '#000000'},
        'hint': {'font': 'Hint.ttf', 'size': 20, 'color': '#FFFFFF'},
      });

      expect(config.currentpage.font, 'Hint.ttf');
      expect(config.currentpage.size, 20);
      expect(config.currentpage.color, const Color(0xFFFFFFFF));
      expect(config.total.font, 'Hint.ttf');
    });

    test('currentpage/total own color overrides the hint fallback', () {
      final config = OnionThemeConfig.fromJson(const {
        'hint': {'color': '#FFFFFF'},
        'currentpage': {'color': '#FF0000'},
      });

      expect(config.currentpage.color, const Color(0xFFFF0000));
      expect(config.total.color, const Color(0xFFFFFFFF));
    });

    test('list falls back to title, not hint', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'font': 'Title.ttf', 'size': 10, 'color': '#000000'},
        'hint': {'font': 'Hint.ttf', 'size': 20, 'color': '#FFFFFF'},
      });

      expect(config.list.font, 'Title.ttf');
      expect(config.list.size, 10);
    });

    test('battery font/color fall back to hint, size/offsets stay static defaults', () {
      final config = OnionThemeConfig.fromJson(const {
        'hint': {'font': 'Hint.ttf', 'color': '#ABCDEF'},
      });

      expect(config.batteryPercentage.font, 'Hint.ttf');
      expect(config.batteryPercentage.color, const Color(0xFFABCDEF));
      expect(config.batteryPercentage.size, 24);
    });

    test('grid has no dynamic fallback to title', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'font': 'Title.ttf', 'size': 99, 'color': '#000000'},
      });

      expect(config.grid.font, kOnionFallbackFontPath);
      expect(config.grid.grid1x4, 24);
    });
  });

  group('OnionThemeConfig.fromJson — legacy keys', () {
    test('hideIconTitle applies to both icons and hints when hideLabels is absent', () {
      final config = OnionThemeConfig.fromJson(const {'hideIconTitle': true});

      expect(config.hideLabels.icons, isTrue);
      expect(config.hideLabels.hints, isTrue);
    });

    test('hideLabels present takes priority over hideIconTitle', () {
      final config = OnionThemeConfig.fromJson(const {
        'hideIconTitle': true,
        'hideLabels': {'icons': false},
      });

      expect(config.hideLabels.icons, isFalse);
      expect(config.hideLabels.hints, isFalse);
    });

    test('hideLabels with only icons leaves hints at its own default', () {
      final config = OnionThemeConfig.fromJson(const {
        'hideLabels': {'icons': true},
      });

      expect(config.hideLabels.icons, isTrue);
      expect(config.hideLabels.hints, isFalse);
    });

    test('onleft: true maps to right alignment', () {
      final config = OnionThemeConfig.fromJson(const {
        'batteryPercentage': {'onleft': true},
      });

      expect(config.batteryPercentage.textAlign, OnionTextAlign.right);
    });

    test('onleft: false maps to left alignment', () {
      final config = OnionThemeConfig.fromJson(const {
        'batteryPercentage': {'onleft': false},
      });

      expect(config.batteryPercentage.textAlign, OnionTextAlign.left);
    });

    test('explicit textAlign takes priority over onleft', () {
      final config = OnionThemeConfig.fromJson(const {
        'batteryPercentage': {'textAlign': 'center', 'onleft': true},
      });

      expect(config.batteryPercentage.textAlign, OnionTextAlign.center);
    });

    test('unknown textAlign string defaults to left', () {
      final config = OnionThemeConfig.fromJson(const {
        'batteryPercentage': {'textAlign': 'somewhere'},
      });

      expect(config.batteryPercentage.textAlign, OnionTextAlign.left);
    });
  });

  group('OnionThemeConfig.fromJson — malformed colors', () {
    test('invalid hex string falls back instead of throwing', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'color': 'not-a-color'},
      });

      expect(config.title.color, OnionThemeConfig.defaults().title.color);
    });

    test('#AARRGGBB ignores the alpha byte', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'color': '#80FF0000'},
      });

      expect(config.title.color, const Color(0xFFFF0000));
    });

    test('color without # prefix still parses', () {
      final config = OnionThemeConfig.fromJson(const {
        'title': {'color': '00FF00'},
      });

      expect(config.title.color, const Color(0xFF00FF00));
    });
  });

  group('OnionThemeConfig.fromJson — real theme fixtures', () {
    test('Blueprint (complete config)', () {
      final config = OnionThemeConfig.fromJson(const {
        'name': 'Blueprint',
        'author': 'Aemiii91',
        'description': 'Theme layout with 10x10 grid',
        'hideLabels': {'icons': false, 'hints': false},
        'batteryPercentage': {
          'visible': true,
          'font': 'OpenSansCondensed-Bold.ttf',
          'size': 11,
          'color': '#FFFFFF',
          'textAlign': 'center',
          'fixed': true,
          'offsetX': 0,
          'offsetY': 0,
        },
        'title': {'font': 'OpenSansCondensed-Bold.ttf', 'size': 36, 'color': '#FFFFFF'},
        'hint': {'font': 'OpenSansCondensed-Bold.ttf', 'size': 40, 'color': '#FFFFFF'},
        'currentpage': {'color': '#FFFFFF'},
        'total': {'color': '#FFFFFF'},
        'grid': {
          'font': 'OpenSansCondensed-Bold.ttf',
          'grid1x4': 25,
          'grid3x4': 18,
          'color': '#FFFFFF',
          'selectedcolor': '#FFFFFF',
        },
        'list': {'font': 'OpenSansCondensed-Bold.ttf', 'size': 25, 'color': '#FFFFFF'},
      });

      expect(config.name, 'Blueprint');
      expect(config.batteryPercentage.visible, isTrue);
      expect(config.batteryPercentage.fixed, isTrue);
      expect(config.batteryPercentage.textAlign, OnionTextAlign.center);
      expect(config.grid.grid1x4, 25);
      expect(config.list.size, 25);
    });

    test('win98 (frame + hideLabels both true, no battery font/color)', () {
      final config = OnionThemeConfig.fromJson(const {
        'name': 'win98',
        'batteryPercentage': {'visible': false},
        'author': 'kyhynngy_oyuur',
        'frame': {'border-left': 9, 'border-right': 9},
        'title': {'font': 'W95FA.otf', 'size': 30, 'color': '#000000'},
        'hint': {'font': 'W95FA.otf', 'size': 0, 'color': '#aaaaaa'},
        'currentpage': {'color': '#aaaaaa'},
        'total': {'color': '#aaaaaa'},
        'grid': {
          'font': 'W95FA.otf',
          'grid1x4': 24,
          'grid3x4': 24,
          'color': '#aaaaaa',
          'selectedcolor': '#d9d9d9',
        },
        'list': {'font': 'W95FA.otf', 'size': 24, 'color': '#aaaaaa'},
        'hideLabels': {'icons': true, 'hints': true},
      });

      expect(config.frame.borderLeft, 9);
      expect(config.frame.borderRight, 9);
      expect(config.hideLabels.icons, isTrue);
      expect(config.hideLabels.hints, isTrue);
      expect(config.hint.size, 0);
      expect(config.batteryPercentage.font, 'W95FA.otf'); // falls back to hint's font
    });

    test('AmalgaM (hideLabels with only icons key)', () {
      final config = OnionThemeConfig.fromJson(const {
        'name': 'AmalgaM',
        'author': 'ZaxxonQ',
        'hideLabels': {'icons': true},
        'batteryPercentage': {
          'visible': false,
          'color': '#ffffff',
          'font': 'wqy-microhei.ttc',
          'size': 30,
        },
        'title': {'font': 'wqy-microhei.ttc', 'size': 30, 'color': '#ffffff'},
        'hint': {'font': 'wqy-microhei.ttc', 'size': 20, 'color': '#ffffff'},
        'currentpage': {'color': '#ffffff'},
        'total': {'color': '#ffffff'},
        'grid': {
          'font': 'wqy-microhei.ttc',
          'grid1x4': 20,
          'grid3x4': 20,
          'color': '#999999',
          'selectedcolor': '#ffffff',
        },
        'list': {'font': 'wqy-microhei.ttc', 'size': 20, 'color': '#ffffff'},
      });

      expect(config.hideLabels.icons, isTrue);
      expect(config.hideLabels.hints, isFalse);
      expect(config.batteryPercentage.size, 30);
    });

    test('999-in-1 (legacy onleft, minimal battery block)', () {
      final config = OnionThemeConfig.fromJson(const {
        'name': '999-in-1',
        'batteryPercentage': {'visible': true, 'onleft': true, 'color': '#000000'},
        'author': 'UnBurn',
        'title': {'font': 'sf-atarian-italic-plus.otf', 'size': 40, 'color': '#000000'},
        'hint': {'font': 'sf-atarian-italic-plus.otf', 'size': 30, 'color': '#606a52'},
        'currentpage': {'color': '#000000'},
        'total': {'color': '#000000'},
        'grid': {
          'font': 'sf-atarian-italic-plus.otf',
          'grid1x4': 30,
          'grid3x4': 50,
          'color': '#606a52',
          'selectedcolor': '#606a52',
        },
        'list': {'font': 'sf-atarian-italic-plus.otf', 'size': 25, 'color': '#606a52'},
        'hideLabels': {'icons': false, 'hints': false},
      });

      expect(config.batteryPercentage.visible, isTrue);
      expect(config.batteryPercentage.textAlign, OnionTextAlign.right);
      expect(config.batteryPercentage.color, const Color(0xFF000000));
    });
  });
}
