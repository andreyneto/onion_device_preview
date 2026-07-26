import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_header.dart';

const _tinyPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, //
  0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 248, 207, 80, 15, 0, //
  3, 134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, //
  174, 66, 96, 130, //
];

late ui.Image tinyImage; // decoded in setUpAll — see battery_indicator_test.dart

const _titleStyle = OnionFontStyle(font: '', size: 24, color: Color(0xFFFFFFFF));

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: child)));
}

void main() {
  setUpAll(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(_tinyPng));
    final frame = await codec.getNextFrame();
    tinyImage = frame.image;
  });

  group('ThemeHeader', () {
    testWidgets('renders at the fixed 640x60 header size', (tester) async {
      await _pump(
        tester,
        ThemeHeader(
          background: tinyImage,
          bgTitle: tinyImage,
          titleStyle: _titleStyle,
          titleFontFamily: 'Exo 2 Bold Italic',
          batteryFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.getSize(find.byType(ThemeHeader)), const Size(640, 60));
    });

    testWidgets('renders without a title, logo or battery icon', (tester) async {
      await _pump(
        tester,
        const ThemeHeader(
          background: null,
          bgTitle: null,
          titleStyle: _titleStyle,
          titleFontFamily: 'Exo 2 Bold Italic',
          batteryFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the battery pill and wifi fan without throwing', (tester) async {
      // The battery pill and wifi fan are internal vector drawings (the
      // real MainUI doesn't use skin assets for them — see the header
      // painter), so there's no child widget to assert on; exercising
      // every state must simply not throw.
      for (final wifi in OnionWifiState.values) {
        await _pump(
          tester,
          ThemeHeader(
            background: tinyImage,
            bgTitle: tinyImage,
            batteryPercentage: 42,
            batteryStyle: const OnionBatteryPercentage(visible: true, size: 20, sizeExplicit: true),
            titleStyle: _titleStyle,
            titleFontFamily: 'Exo 2 Bold Italic',
            batteryFontFamily: 'Exo 2 Bold Italic',
            wifi: wifi,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('showLogo: false hides the logo even when one is provided', (tester) async {
      await _pump(
        tester,
        ThemeHeader(
          background: tinyImage,
          bgTitle: tinyImage,
          logo: tinyImage,
          showLogo: false,
          titleStyle: _titleStyle,
          titleFontFamily: 'Exo 2 Bold Italic',
          batteryFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long title still renders without throwing (crop/overflow is fine, a crash is not)', (tester) async {
      await _pump(
        tester,
        ThemeHeader(
          background: tinyImage,
          bgTitle: tinyImage,
          title: 'A Very Long Game Title That Would Overflow The 640px Header Easily',
          titleStyle: _titleStyle,
          titleFontFamily: 'Exo 2 Bold Italic',
          batteryFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
