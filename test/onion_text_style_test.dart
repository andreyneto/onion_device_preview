import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/onion_canvas.dart';

/// Guards the SDL_ttf synthetic-bold advance that only the list font gets
/// (`resources.h:258`). See onionTextStyle and docs/spec-1a1.md §11.11.
void main() {
  const style = OnionFontStyle(font: '', size: 25, color: Color(0xFFFFFFFF));

  group('onionTextStyle — synthetic bold advance', () {
    test('bold widens every glyph by y_ppem / 10, integer-divided', () {
      // Stock list size is 25, so the device gains exactly 2px per glyph.
      expect(onionTextStyle(style, fontFamily: '', bold: true).letterSpacing, 2.0);

      const small = OnionFontStyle(font: '', size: 18, color: Color(0xFFFFFFFF));
      expect(onionTextStyle(small, fontFamily: '', bold: true).letterSpacing, 1.0);

      // Integer division, not rounding: 29 / 10 is 2, not 3.
      const odd = OnionFontStyle(font: '', size: 29, color: Color(0xFFFFFFFF));
      expect(onionTextStyle(odd, fontFamily: '', bold: true).letterSpacing, 2.0);
    });

    test('non-bold text is untouched — the firmware bolds the list font only', () {
      expect(onionTextStyle(style, fontFamily: '', bold: false).letterSpacing, isNull);
    });

    test('the advance actually reaches laid-out text', () {
      final plain = OnionCanvasOps.layoutOnionText('Change language', style: style, fontFamily: '');
      final bold = OnionCanvasOps.layoutOnionText('Change language', style: style, fontFamily: '', bold: true);

      // 15 glyphs x 2px. Measured on the device at 28px of extra ink across
      // the same string (14 inter-glyph gaps) in docs/images/device-vs-render.png.
      expect(bold.width - plain.width, greaterThanOrEqualTo(28.0));
    });
  });
}
