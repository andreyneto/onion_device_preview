import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import 'onion_canvas.dart';

/// What a list row shows on its right edge, mirroring `ItemType` in
/// `Onion/src/common/theme/render/list.h:141-173`.
enum OnionListItemControl { none, toggle, multivalue }

/// Alpha applied to a disabled-but-visible row's text/controls, matching
/// `HIDDEN_ITEM_ALPHA` (`resources.h:22`, on a 0-255 scale).
const double kOnionHiddenItemOpacity = 60 / 255;

/// A single row of a themed list — background highlight, leading icon,
/// bold label, optional description (large rows only), and an optional
/// trailing toggle or multivalue control. Mirrors the per-item drawing in
/// `theme_renderListCustom` (`Onion/src/common/theme/render/list.h:102-183`);
/// the surrounding list (scrolling, anchoring to the screen bottom, the
/// active item's cover-art preview) is a screen-level concern (M3), not
/// this widget's.
class ThemeListItem extends StatelessWidget {
  const ThemeListItem({
    super.key,
    required this.width,
    this.large = false,
    this.selected = false,
    this.disabled = false,
    this.showDivider = false,
    this.dividerImage,
    this.selectedBackground,
    this.icon,
    this.fixedIconColumn = false,
    required this.label,
    this.description,
    required this.listStyle,
    required this.listFontFamily,
    this.descriptionColor = const Color(0xFF686868),
    this.control = OnionListItemControl.none,
    this.toggleOn = false,
    this.toggleOnImage,
    this.toggleOffImage,
    this.multivalueText,
    this.leftArrowImage,
    this.rightArrowImage,
    this.trailingMark,
  });

  /// Row width — 640 for a full-screen list, narrower for e.g. a pop menu.
  final double width;

  /// `false` = 60px row (`LIST_SMALL`); `true` = 90px row.
  final bool large;

  final bool selected;
  final bool disabled;

  /// Whether a divider is drawn above this row. Also affects vertical
  /// padding on small rows (list.h:67).
  final bool showDivider;

  final ui.Image? dividerImage;
  final ui.Image? selectedBackground;
  final ui.Image? icon;

  /// Start the label at a fixed x instead of after the icon — what the
  /// device's Settings menu does. See the constant in the painter.
  final bool fixedIconColumn;

  final String label;
  final String? description;
  final OnionFontStyle listStyle;
  final String listFontFamily;
  final Color descriptionColor;

  final OnionListItemControl control;
  final bool toggleOn;
  final ui.Image? toggleOnImage;
  final ui.Image? toggleOffImage;
  final String? multivalueText;
  final ui.Image? leftArrowImage;
  final ui.Image? rightArrowImage;

  /// A small marker drawn against the row's right edge (the device's
  /// favorite star, `ic-favorite-mark` — MainUI_011 reference: x=586 for
  /// a 34px mark, i.e. 20px off the right edge, vertically centered).
  final ui.Image? trailingMark;

  // Small rows: the focused `bg-list-s` blit covers the full 60px band
  // and text sits with its center at row+31.5, both measured off device
  // screenshots (MainUI_008/009/010 — glyph centers 93/153.5/213.5 on
  // rows starting at 62). The old 56px+4 inset came from `list.h`'s
  // divider math, which MainUI's own lists don't use.
  double get _rowHeight => large ? 90 : 60;
  double get _bgHeight => large ? 90 : 60;
  double get _contentTop => (!large && showDivider) ? 4 : 0;
  double get _labelCenterY => _contentTop + (large ? 37 : 31.5);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _rowHeight,
      child: CustomPaint(
        painter: _ThemeListItemPainter(
          width: width,
          bgHeight: _bgHeight,
          contentTop: _contentTop,
          labelCenterY: _labelCenterY,
          large: large,
          selected: selected,
          disabled: disabled,
          showDivider: showDivider,
          dividerImage: dividerImage,
          selectedBackground: selectedBackground,
          icon: icon,
          fixedIconColumn: fixedIconColumn,
          label: label,
          description: description,
          listStyle: listStyle,
          listFontFamily: listFontFamily,
          descriptionColor: descriptionColor,
          control: control,
          toggleOn: toggleOn,
          toggleOnImage: toggleOnImage,
          toggleOffImage: toggleOffImage,
          multivalueText: multivalueText,
          leftArrowImage: leftArrowImage,
          rightArrowImage: rightArrowImage,
          trailingMark: trailingMark,
        ),
      ),
    );
  }
}

class _ThemeListItemPainter extends CustomPainter {
  const _ThemeListItemPainter({
    required this.width,
    required this.bgHeight,
    required this.contentTop,
    required this.labelCenterY,
    required this.large,
    required this.selected,
    required this.disabled,
    required this.showDivider,
    required this.dividerImage,
    required this.selectedBackground,
    required this.icon,
    required this.fixedIconColumn,
    required this.label,
    required this.description,
    required this.listStyle,
    required this.listFontFamily,
    required this.descriptionColor,
    required this.control,
    required this.toggleOn,
    required this.toggleOnImage,
    required this.toggleOffImage,
    required this.multivalueText,
    required this.leftArrowImage,
    required this.rightArrowImage,
    required this.trailingMark,
  });

  final double width;
  final double bgHeight;
  final double contentTop;
  final double labelCenterY;
  final bool large;
  final bool selected;
  final bool disabled;
  final bool showDivider;
  final ui.Image? dividerImage;
  final ui.Image? selectedBackground;
  final ui.Image? icon;
  final bool fixedIconColumn;
  final String label;
  final String? description;
  final OnionFontStyle listStyle;
  final String listFontFamily;
  final Color descriptionColor;
  final OnionListItemControl control;
  final bool toggleOn;
  final ui.Image? toggleOnImage;
  final ui.Image? toggleOffImage;
  final String? multivalueText;
  final ui.Image? leftArrowImage;
  final ui.Image? rightArrowImage;
  final ui.Image? trailingMark;

  static const double _edgeMargin = 20;
  static const double _iconGap = 17;

  /// Where the label starts on a Settings row [MEAS-device].
  ///
  /// `list.h:132-137` advances the pen by the icon's own width
  /// (`offset_x += icon->w + 17`), and that is what the Apps list does —
  /// verified against MainUI_013 with its 74px pack icons (spec §12.3).
  /// The Settings menu does *not*: cross-correlating each label against
  /// MainUI_012 puts the pen on 80 in every row while the icon widths
  /// vary 46–48, so it can't be icon-relative there. MainUI is closed, so
  /// the two lists are presumably separate code paths; the discriminator
  /// we can see from outside is which icon source the row uses. See spec
  /// §11.12.
  static const double _skinIconColumnEnd = 80;

  // Multivalue geometry [MEAS-device] (MainUI_012, Brightness row): the
  // 24px arrow canvases sit at x=352 and x=576 on a 640 row (i.e. the
  // right arrow is 40px off the edge), with the value centered in the
  // 200px band between them (center x=476).
  static const double _arrowEdgeMargin = 40;
  static const double _multivalueWidth = 200;

  @override
  void paint(Canvas canvas, Size size) {
    if (showDivider) {
      canvas.drawImageRegion(
        dividerImage,
        from: Rect.fromLTWH(0, 0, width, 4),
        to: Rect.fromLTWH(0, 0, width, 4),
      );
    }

    if (selected && selectedBackground != null) {
      // Full-canvas blit, vertically centered in the row band and
      // clipped to the row's width — a theme's bar may be shorter than
      // the 60px band (e.g. 640x56) and region-cropping would read past
      // its bounds. Left-aligned horizontally: narrower surfaces (the
      // 320px pop menu) show the bar's left portion, like the device.
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, contentTop, width, bgHeight));
      canvas.drawImageTopLeft(
        selectedBackground,
        Offset(0, contentTop + (bgHeight - selectedBackground!.height) / 2),
      );
      canvas.restore();
    }

    final centerY = contentTop + bgHeight / 2;
    final opacity = disabled ? kOnionHiddenItemOpacity : 1.0;

    var offsetX = _edgeMargin;
    if (icon != null) {
      canvas.drawImageTopLeft(icon, Offset(offsetX, centerY - icon!.height / 2));
      offsetX = fixedIconColumn ? _skinIconColumnEnd : offsetX + icon!.width + _iconGap;
    }

    var labelEnd = width;
    var labelEndGap = 0.0;

    if (trailingMark != null) {
      canvas.drawImageTopLeft(
        trailingMark,
        Offset(width - _edgeMargin - trailingMark!.width, centerY - trailingMark!.height / 2),
      );
      labelEnd = width - _edgeMargin - trailingMark!.width;
      labelEndGap = 10;
    }

    switch (control) {
      case OnionListItemControl.toggle:
        final toggleImage = toggleOn ? toggleOnImage : toggleOffImage;
        if (toggleImage != null) {
          final toggleX = width - _edgeMargin - toggleImage.width;
          canvas.drawImageTopLeft(toggleImage, Offset(toggleX, centerY - toggleImage.height / 2));
          labelEnd = toggleX;
          labelEndGap = 10;
        }
      case OnionListItemControl.multivalue:
        final rightW = rightArrowImage?.width.toDouble() ?? 0;
        final leftW = leftArrowImage?.width.toDouble() ?? 0;
        final arrowRightX = width - _arrowEdgeMargin - rightW;
        final arrowLeftX = arrowRightX - _multivalueWidth - leftW;
        if (rightArrowImage != null) {
          canvas.drawImageTopLeft(rightArrowImage, Offset(arrowRightX, centerY - rightArrowImage!.height / 2));
        }
        if (leftArrowImage != null) {
          canvas.drawImageTopLeft(leftArrowImage, Offset(arrowLeftX, centerY - leftArrowImage!.height / 2));
        }
        labelEnd = arrowLeftX;
        labelEndGap = 10;

        if (multivalueText != null && multivalueText!.isNotEmpty) {
          final bandLeft = arrowLeftX + leftW;
          final value = OnionCanvasOps.layoutOnionText(
            multivalueText!,
            style: listStyle,
            fontFamily: listFontFamily,
            bold: true,
          );
          final labelWidth = value.width > _multivalueWidth ? _multivalueWidth : value.width;
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(bandLeft, 0, _multivalueWidth, size.height));
          value.paint(canvas, Offset(bandLeft + (_multivalueWidth - labelWidth) / 2, centerY - value.height / 2));
          canvas.restore();
        }
      case OnionListItemControl.none:
        break;
    }

    // Hard clip against the row's usable end, like the device: a long
    // title is cut mid-glyph at the screen edge, no ellipsis (MainUI_010
    // reference). Only rows with a trailing control keep a 10px breathing
    // gap before it.
    final availableWidth = (labelEnd - offsetX - labelEndGap).clamp(0.0, width);

    _drawCenteredLabel(canvas, label, offsetX, labelCenterY, availableWidth, listStyle, opacity: opacity);

    if (large && description != null && description!.isNotEmpty) {
      final descStyle = OnionFontStyle(font: listStyle.font, size: listStyle.size, color: descriptionColor);
      _drawCenteredLabel(canvas, description!, offsetX, contentTop + 62, availableWidth, descStyle, opacity: opacity);
    }
  }

  /// Lays out [text] bold in [style] (opacity baked into the color, since
  /// it must be set before layout), clips it to [clipWidth] starting at
  /// [x], and paints it vertically centered on [centerY].
  void _drawCenteredLabel(
    Canvas canvas,
    String text,
    double x,
    double centerY,
    double clipWidth,
    OnionFontStyle style, {
    required double opacity,
  }) {
    final fadedStyle = OnionFontStyle(
      font: style.font,
      size: style.size,
      color: style.color.withAlpha((opacity.clamp(0, 1) * 0xFF).round()),
    );
    final painter = OnionCanvasOps.layoutOnionText(text, style: fadedStyle, fontFamily: listFontFamily, bold: true);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(x, 0, clipWidth, painter.height * 2 + centerY.abs()));
    painter.paint(canvas, Offset(x, centerY - painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThemeListItemPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.disabled != disabled ||
        oldDelegate.label != label ||
        oldDelegate.description != description ||
        oldDelegate.control != control ||
        oldDelegate.toggleOn != toggleOn ||
        oldDelegate.multivalueText != multivalueText ||
        oldDelegate.trailingMark != trailingMark ||
        oldDelegate.fixedIconColumn != fixedIconColumn ||
        // Images can arrive after the first paint (async icon loads) —
        // skipping them here freezes the row on its icon-less frame.
        oldDelegate.icon != icon ||
        oldDelegate.selectedBackground != selectedBackground ||
        oldDelegate.dividerImage != dividerImage ||
        oldDelegate.toggleOnImage != toggleOnImage ||
        oldDelegate.toggleOffImage != toggleOffImage ||
        oldDelegate.leftArrowImage != leftArrowImage ||
        oldDelegate.rightArrowImage != rightArrowImage;
  }
}
