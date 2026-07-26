import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_footer.dart';

const _tinyPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, //
  0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 248, 207, 80, 15, 0, //
  3, 134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, //
  174, 66, 96, 130, //
];

late ui.Image tinyImage;

const _hintStyle = OnionFontStyle(font: '', size: 20, color: Color(0xFFFFFFFF));

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: child)));
}

void main() {
  setUpAll(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(_tinyPng));
    final frame = await codec.getNextFrame();
    tinyImage = frame.image;
  });

  group('ThemeFooter', () {
    testWidgets('renders at the fixed 640x60 footer size', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.getSize(find.byType(ThemeFooter)), const Size(640, 60));
    });

    testWidgets('renders with everything absent without throwing', (tester) async {
      await _pump(
        tester,
        const ThemeFooter(hintStyle: _hintStyle, hintFontFamily: 'Exo 2 Bold Italic'),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('button B and its label only render when showButtonB is true', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          buttonAIcon: tinyImage,
          buttonBIcon: tinyImage,
          hintLabelA: 'Select',
          hintLabelB: 'Back',
          showButtonB: false,
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('hideLabels suppresses hint text but does not throw', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          buttonAIcon: tinyImage,
          buttonBIcon: tinyImage,
          hintLabelA: 'Select',
          hintLabelB: 'Back',
          showButtonB: true,
          hideLabels: true,
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the page counter forces current to 0 when total is 0', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          currentPage: 5, // should be ignored/forced to 0
          totalPages: 0,
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with a real page counter without throwing', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          currentPage: 3,
          totalPages: 42,
          currentPageColor: const Color(0xFF00FF00),
          totalColor: const Color(0xFFFF0000),
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('no page counter is shown when totalPages is null', (tester) async {
      await _pump(
        tester,
        ThemeFooter(
          background: tinyImage,
          bgFooter: tinyImage,
          hintStyle: _hintStyle,
          hintFontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ThemeFooter), findsOneWidget);
    });
  });
}
