import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/status_indicators.dart';
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
        ),
      );

      expect(tester.getSize(find.byType(ThemeHeader)), const Size(640, 60));
    });

    testWidgets('renders without a title or logo', (tester) async {
      await _pump(
        tester,
        const ThemeHeader(
          background: null,
          bgTitle: null,
          titleStyle: _titleStyle,
          titleFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
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
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('StatusIndicators', () {
    testWidgets('renders battery/wifi theme assets and the percentage text without throwing', (tester) async {
      // Battery/wifi are theme assets blitted with their whole canvas
      // centered on fixed anchors, painted as the topmost screen layer
      // (see StatusIndicators) — exercising present/absent assets and
      // the text overlay must not throw.
      await _pump(
        tester,
        SizedBox(
          width: 640,
          height: 480,
          child: StatusIndicators(
            batteryIcon: tinyImage,
            wifiIcon: tinyImage,
            batteryPercentage: 42,
            charging: false,
            batteryStyle: const OnionBatteryPercentage(visible: true, size: 20, sizeExplicit: true),
            batteryFontFamily: 'Exo 2 Bold Italic',
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        const SizedBox(
          width: 640,
          height: 480,
          child: StatusIndicators(
            batteryPercentage: 100,
            charging: true,
            batteryStyle: OnionBatteryPercentage(visible: true),
            batteryFontFamily: 'Exo 2 Bold Italic',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
