import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_list_item.dart';

const _tinyPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, //
  0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 248, 207, 80, 15, 0, //
  3, 134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, //
  174, 66, 96, 130, //
];

late ui.Image tinyImage;

const _listStyle = OnionFontStyle(font: '', size: 24, color: Color(0xFFFFFFFF));

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: child)));
}

void main() {
  setUpAll(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(_tinyPng));
    final frame = await codec.getNextFrame();
    tinyImage = frame.image;
  });

  group('ThemeListItem — sizing', () {
    testWidgets('small row is 60px tall', (tester) async {
      await _pump(tester, const ThemeListItem(width: 640, label: 'Game A', listStyle: _listStyle, listFontFamily: 'x'));

      expect(tester.getSize(find.byType(ThemeListItem)), const Size(640, 60));
    });

    testWidgets('large row is 90px tall', (tester) async {
      await _pump(
        tester,
        const ThemeListItem(width: 640, large: true, label: 'Game A', listStyle: _listStyle, listFontFamily: 'x'),
      );

      expect(tester.getSize(find.byType(ThemeListItem)), const Size(640, 90));
    });

    testWidgets('honors a narrower width (e.g. a pop menu)', (tester) async {
      await _pump(tester, const ThemeListItem(width: 320, label: 'Option', listStyle: _listStyle, listFontFamily: 'x'));

      expect(tester.getSize(find.byType(ThemeListItem)), const Size(320, 60));
    });
  });

  group('ThemeListItem — rendering without throwing', () {
    testWidgets('a bare unselected row with just a label', (tester) async {
      await _pump(tester, const ThemeListItem(width: 640, label: 'Plain Item', listStyle: _listStyle, listFontFamily: 'x'));

      expect(tester.takeException(), isNull);
    });

    testWidgets('selected + divider + icon', (tester) async {
      await _pump(
        tester,
        ThemeListItem(
          width: 640,
          selected: true,
          showDivider: true,
          dividerImage: tinyImage,
          selectedBackground: tinyImage,
          icon: tinyImage,
          label: 'Selected Item',
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('large row with a description', (tester) async {
      await _pump(
        tester,
        const ThemeListItem(
          width: 640,
          large: true,
          label: 'Setting name',
          description: 'A short description of the setting',
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('small row ignores description even if provided', (tester) async {
      await _pump(
        tester,
        const ThemeListItem(
          width: 640,
          label: 'Rom name',
          description: 'Should not render on a small row',
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('toggle control (on and off) renders without throwing', (tester) async {
      for (final on in [true, false]) {
        await _pump(
          tester,
          ThemeListItem(
            width: 640,
            label: 'Enable something',
            control: OnionListItemControl.toggle,
            toggleOn: on,
            toggleOnImage: tinyImage,
            toggleOffImage: tinyImage,
            listStyle: _listStyle,
            listFontFamily: 'x',
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('multivalue control with a value label renders without throwing', (tester) async {
      await _pump(
        tester,
        ThemeListItem(
          width: 640,
          label: 'Brightness',
          control: OnionListItemControl.multivalue,
          multivalueText: '7',
          leftArrowImage: tinyImage,
          rightArrowImage: tinyImage,
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a very long label does not throw (clipped, not crashed)', (tester) async {
      await _pump(
        tester,
        ThemeListItem(
          width: 640,
          icon: tinyImage,
          label: 'A' * 200,
          control: OnionListItemControl.toggle,
          toggleOnImage: tinyImage,
          toggleOffImage: tinyImage,
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled row (dimmed) renders without throwing', (tester) async {
      await _pump(
        tester,
        ThemeListItem(
          width: 640,
          disabled: true,
          icon: tinyImage,
          label: 'Disabled item',
          large: true,
          description: 'also dimmed',
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('every asset missing (null) still renders without throwing', (tester) async {
      await _pump(
        tester,
        const ThemeListItem(
          width: 640,
          selected: true,
          showDivider: true,
          label: 'No assets at all',
          control: OnionListItemControl.multivalue,
          multivalueText: 'X',
          listStyle: _listStyle,
          listFontFamily: 'x',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
