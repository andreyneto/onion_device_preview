import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/battery_indicator.dart';

const _tinyPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, //
  0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 248, 207, 80, 15, 0, //
  3, 134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, //
  174, 66, 96, 130, //
];

// Decoded once in `setUpAll`, which runs in real async time — decoding a
// real image inside a `testWidgets` body hangs, because `instantiateImageCodec`
// is genuine engine-level async work that never resolves inside the
// FakeAsync zone `testWidgets` runs its callback in.
late ui.Image tinyImage;

Future<Size> _pumpAndMeasure(WidgetTester tester, BatteryIndicator widget) async {
  // Center (rather than Directionality alone) gives the CustomPaint loose
  // constraints, so it sizes to its intrinsic `size` instead of being
  // stretched to the 800x600 test viewport.
  await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: widget)));
  return tester.getSize(find.byType(BatteryIndicator));
}

void main() {
  setUpAll(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(_tinyPng));
    final frame = await codec.getNextFrame();
    tinyImage = frame.image;
  });

  group('BatteryIndicator', () {
    testWidgets('an invisible battery (visible: false) sizes to just the icon, min 48x48', (tester) async {
      final size = await _pumpAndMeasure(
        tester,
        BatteryIndicator(
          icon: tinyImage,
          percentage: 65,
          charging: false,
          style: const OnionBatteryPercentage(visible: false),
          fontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(size, const Size(48, 48));
    });

    testWidgets('charging forces the text hidden even if visible: true', (tester) async {
      final visibleSize = await _pumpAndMeasure(
        tester,
        BatteryIndicator(
          icon: tinyImage,
          percentage: 65,
          charging: false,
          style: const OnionBatteryPercentage(visible: true, size: 24),
          fontFamily: 'Exo 2 Bold Italic',
        ),
      );

      final chargingSize = await _pumpAndMeasure(
        tester,
        BatteryIndicator(
          icon: tinyImage,
          percentage: 65,
          charging: true,
          style: const OnionBatteryPercentage(visible: true, size: 24),
          fontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(chargingSize, const Size(48, 48)); // icon-only size
      expect(visibleSize.width, greaterThan(chargingSize.width)); // text adds width
    });

    testWidgets('fixed/center composites are no wider than the unfixed left/right layout', (tester) async {
      Future<Size> sizeFor(OnionBatteryPercentage style) => _pumpAndMeasure(
            tester,
            BatteryIndicator(icon: tinyImage, percentage: 42, charging: false, style: style, fontFamily: 'Exo 2 Bold Italic'),
          );

      final unfixedLeft = await sizeFor(const OnionBatteryPercentage(visible: true, size: 24));
      final fixedCenter = await sizeFor(const OnionBatteryPercentage(visible: true, size: 24, fixed: true, textAlign: OnionTextAlign.center));
      final unfixedCenter = await sizeFor(const OnionBatteryPercentage(visible: true, size: 24, textAlign: OnionTextAlign.center));

      // Unfixed left/right reserves 2x(text+spacer)+icon; fixed/center only
      // needs max(icon, text) — see battery.h:59 vs :66-68.
      expect(fixedCenter.width, lessThan(unfixedLeft.width));
      // textAlign: center forces the same (fixed-style) sizing regardless
      // of `fixed` itself (battery.h:66).
      expect(unfixedCenter.width, fixedCenter.width);
    });

    testWidgets('every alignment x fixed combination renders without throwing', (tester) async {
      for (final align in OnionTextAlign.values) {
        for (final fixed in [true, false]) {
          await _pumpAndMeasure(
            tester,
            BatteryIndicator(
              icon: tinyImage,
              percentage: 7,
              charging: false,
              style: OnionBatteryPercentage(visible: true, size: 20, fixed: fixed, textAlign: align),
              fontFamily: 'Exo 2 Bold Italic',
            ),
          );
        }
      }
    });

    testWidgets('a null icon (missing asset) still lays out using the 48x48 fallback size', (tester) async {
      final size = await _pumpAndMeasure(
        tester,
        const BatteryIndicator(
          icon: null,
          percentage: 50,
          charging: false,
          style: OnionBatteryPercentage(visible: false),
          fontFamily: 'Exo 2 Bold Italic',
        ),
      );

      expect(size, const Size(48, 48));
    });
  });
}
