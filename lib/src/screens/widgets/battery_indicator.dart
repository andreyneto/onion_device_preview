import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import 'onion_canvas.dart';

/// Renders the battery icon plus its optional percentage text as a single
/// composite, sized and laid out exactly like
/// `theme_batterySurfaceWithBg` (`Onion/src/common/theme/render/battery.h`)
/// — minus the SDL background-crop trick used there purely to get correct
/// alpha blending on a flattened bitmap surface; Flutter's canvas already
/// alpha-composites against whatever is drawn underneath, so that step
/// has no equivalent here.
///
/// Center this widget at (596, 30) to match `render/header.h:19`, e.g.
/// via `Positioned(left: 596, top: 30, child: FractionalTranslation(
/// translation: Offset(-0.5, -0.5), child: BatteryIndicator(...)))`.
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.icon,
    required this.percentage,
    required this.charging,
    required this.style,
    required this.fontFamily,
  });

  final ui.Image? icon;
  final int percentage;
  final bool charging;
  final OnionBatteryPercentage style;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final layout = _BatteryLayout.compute(
      icon: icon,
      percentage: percentage,
      charging: charging,
      style: style,
      fontFamily: fontFamily,
    );
    return CustomPaint(size: layout.size, painter: _BatteryPainter(layout));
  }

  /// Paints the composite with its whole canvas centered on [center] —
  /// exactly how the header blits it (`header.h:19`, and
  /// `theme_renderHeaderBatteryCustom` for a custom bar's height).
  ///
  /// Callers that draw the status bar by hand must go through this rather
  /// than placing icon and text independently: the percentage's position
  /// is defined *inside* the composite (`offsetX` is relative to the
  /// canvas's left edge, not to the anchor), so centering the text on the
  /// anchor gets it wrong for any theme with a non-zero `offsetX` — stock
  /// Silky's 26 put it 26px too far right. See spec §11.13.
  static void paintCenteredAt(
    Canvas canvas,
    Offset center, {
    required ui.Image? icon,
    required int percentage,
    required bool charging,
    required OnionBatteryPercentage style,
    required String fontFamily,
  }) {
    final layout = _BatteryLayout.compute(
      icon: icon,
      percentage: percentage,
      charging: charging,
      style: style,
      fontFamily: fontFamily,
    );
    layout.paintAt(canvas, center - Offset(layout.size.width / 2, layout.size.height / 2));
  }

  /// The composite's total width for the given inputs, so siblings (the
  /// header's wifi icon) can position themselves relative to its left
  /// edge without rebuilding the layout math.
  static double compositeWidth({
    required ui.Image? icon,
    required int percentage,
    required bool charging,
    required OnionBatteryPercentage style,
    required String fontFamily,
  }) {
    return _BatteryLayout.compute(
      icon: icon,
      percentage: percentage,
      charging: charging,
      style: style,
      fontFamily: fontFamily,
    ).size.width;
  }
}

class _BatteryLayout {
  const _BatteryLayout({
    required this.size,
    required this.icon,
    required this.iconOffset,
    this.textPainter,
    this.textOffset,
  });

  final Size size;
  final ui.Image? icon;
  final Offset iconOffset;
  final TextPainter? textPainter;
  final Offset? textOffset;

  static const int _spacer = 5;

  static _BatteryLayout compute({
    required ui.Image? icon,
    required int percentage,
    required bool charging,
    required OnionBatteryPercentage style,
    required String fontFamily,
  }) {
    final iconSize = icon == null ? const Size(48, 48) : Size(icon.width.toDouble(), icon.height.toDouble());

    // "Currently charging, hide text" (battery.h:28-29) and the
    // icon-too-wide-for-the-screen guard (battery.h:55-56).
    var visible = style.visible && !charging && iconSize.width <= 640;

    TextPainter? textPainter;
    if (visible) {
      final fontStyle = OnionFontStyle(font: style.font, size: style.size, color: style.color);
      textPainter = OnionCanvasOps.layoutOnionText('$percentage%', style: fontStyle, fontFamily: fontFamily);
    }
    final textSize = textPainter?.size ?? Size.zero;

    double width;
    double height;
    if (!visible) {
      width = iconSize.width;
      height = iconSize.height;
    } else if (style.fixed || style.textAlign == OnionTextAlign.center) {
      width = iconSize.width > textSize.width ? iconSize.width : textSize.width;
      height = textSize.height > iconSize.height ? textSize.height : iconSize.height;
    } else {
      width = 2 * (textSize.width + _spacer) + iconSize.width;
      height = textSize.height > iconSize.height ? textSize.height : iconSize.height;
    }

    if (width % 2 != 0) width += 1;
    if (height % 2 != 0) height += 1;
    if (width < 48) width = 48;
    if (height < 48) height = 48;

    var iconOffset = Offset(0, (height - iconSize.height) / 2);
    Offset? textOffset;

    if (visible) {
      // Exo 2's glyph metrics sit a bit low relative to its nominal
      // height; the firmware nudges the baseline up to compensate
      // (battery.h:34-36).
      var offsetY = style.offsetY.toDouble();
      if (fontFamily.contains('Exo 2')) {
        offsetY -= 0.075 * textSize.height;
      }
      textOffset = Offset(0, (height - textSize.height) / 2 + offsetY);

      if (style.fixed) {
        switch (style.textAlign) {
          case OnionTextAlign.right:
            textOffset = Offset(iconSize.width - textSize.width + style.offsetX, textOffset.dy);
          case OnionTextAlign.center:
            textOffset = Offset((iconSize.width - textSize.width) / 2 + style.offsetX, textOffset.dy);
          case OnionTextAlign.left:
            textOffset = Offset(style.offsetX.toDouble(), textOffset.dy);
        }
      } else {
        switch (style.textAlign) {
          case OnionTextAlign.right:
            iconOffset = Offset(textSize.width + _spacer, iconOffset.dy);
            textOffset = Offset(style.offsetX.toDouble(), textOffset.dy);
          case OnionTextAlign.center:
            textOffset = Offset((iconSize.width - textSize.width) / 2 + style.offsetX, textOffset.dy);
          case OnionTextAlign.left:
            textOffset = Offset(iconSize.width + _spacer + style.offsetX, textOffset.dy);
        }
      }
    }

    return _BatteryLayout(
      size: Size(width, height),
      icon: icon,
      iconOffset: iconOffset,
      textPainter: textPainter,
      textOffset: textOffset,
    );
  }

  /// Draws the composite with its top-left corner at [origin].
  void paintAt(Canvas canvas, Offset origin) {
    canvas.drawImageTopLeft(icon, origin + iconOffset);
    if (textPainter != null && textOffset != null) {
      textPainter!.paint(canvas, origin + textOffset!);
    }
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter(this.layout);

  final _BatteryLayout layout;

  @override
  void paint(Canvas canvas, Size size) => layout.paintAt(canvas, Offset.zero);

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.layout.icon != layout.icon ||
        oldDelegate.layout.textPainter?.text != layout.textPainter?.text ||
        oldDelegate.layout.size != layout.size;
  }
}
