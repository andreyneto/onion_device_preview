import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import 'onion_canvas.dart';

/// The 640x60 footer bar: background + `tips-bar-bg`, the A/B button
/// hints, and an optional page counter — mirrors `theme_renderFooter`,
/// `theme_renderStandardHint` and `theme_renderFooterStatus`
/// (`Onion/src/common/theme/render/footer.h`).
///
/// [hintLabelB]/[buttonBIcon] only render when [showButtonB] is true —
/// the firmware's own condition is "was a B action even passed in for
/// this screen", not whether the label text is empty (a hidden label is
/// still a space character, not nothing).
///
/// [currentPage]/[totalPages] are optional: not every screen shows a
/// page counter (only paginated lists do, via `theme_renderListFooter`).
class ThemeFooter extends StatelessWidget {
  const ThemeFooter({
    super.key,
    this.background,
    this.bgFooter,
    this.buttonAIcon,
    this.buttonBIcon,
    this.hintLabelA,
    this.hintLabelB,
    this.hideLabels = false,
    this.showButtonB = false,
    this.currentPage,
    this.totalPages,
    required this.hintStyle,
    required this.hintFontFamily,
    this.currentPageColor = const Color(0xFFFFFFFF),
    this.totalColor = const Color(0xFFFFFFFF),
  });

  static const double width = 640;
  static const double height = 60;

  /// Where this bar sits on the 640x480 screen — used only to crop the
  /// right strip out of the full-screen [background] image.
  static const double screenTop = 420;

  final ui.Image? background;
  final ui.Image? bgFooter;
  final ui.Image? buttonAIcon;
  final ui.Image? buttonBIcon;
  final String? hintLabelA;
  final String? hintLabelB;
  final bool hideLabels;
  final bool showButtonB;
  final int? currentPage;
  final int? totalPages;
  final OnionFontStyle hintStyle;
  final String hintFontFamily;
  final Color currentPageColor;
  final Color totalColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ThemeFooterPainter(
          background: background,
          bgFooter: bgFooter,
          buttonAIcon: buttonAIcon,
          buttonBIcon: buttonBIcon,
          hintLabelA: hideLabels ? null : hintLabelA,
          hintLabelB: hideLabels ? null : hintLabelB,
          showButtonB: showButtonB,
          currentPage: currentPage,
          totalPages: totalPages,
          hintStyle: hintStyle,
          hintFontFamily: hintFontFamily,
          currentPageColor: currentPageColor,
          totalColor: totalColor,
        ),
      ),
    );
  }
}

class _ThemeFooterPainter extends CustomPainter {
  const _ThemeFooterPainter({
    required this.background,
    required this.bgFooter,
    required this.buttonAIcon,
    required this.buttonBIcon,
    required this.hintLabelA,
    required this.hintLabelB,
    required this.showButtonB,
    required this.currentPage,
    required this.totalPages,
    required this.hintStyle,
    required this.hintFontFamily,
    required this.currentPageColor,
    required this.totalColor,
  });

  final ui.Image? background;
  final ui.Image? bgFooter;
  final ui.Image? buttonAIcon;
  final ui.Image? buttonBIcon;
  final String? hintLabelA;
  final String? hintLabelB;
  final bool showButtonB;
  final int? currentPage;
  final int? totalPages;
  final OnionFontStyle hintStyle;
  final String hintFontFamily;
  final Color currentPageColor;
  final Color totalColor;

  // Firmware constants (footer.h), translated from absolute screen Y
  // (420-480) into this widget's own local 0-60 coordinate space.
  static const double _buttonCenterY = 450 - ThemeFooter.screenTop; // 30
  static const double _labelCenterY = 449 - ThemeFooter.screenTop; // 29
  static const double _spacer = 5;
  static const double _labelGap = 30;
  static const double _counterRightEdge = 620;

  // MainUI draws the footer legend and page counter at ~25px regardless
  // of the theme's hint.size ([MEAS-device]: 'SELECT' cap-height 18 and
  // '1/3' 19 on MainUI_004, with Silky's config explicitly setting
  // hint.size 40 — the bar ignores it; hint.size still applies to
  // dialogs). Font family and colors keep following the theme.
  static const int _footerTextSize = 25;

  OnionFontStyle _footerStyle(Color color) =>
      OnionFontStyle(font: hintStyle.font, size: _footerTextSize, color: color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRegion(
      background,
      from: const Rect.fromLTWH(0, ThemeFooter.screenTop, ThemeFooter.width, ThemeFooter.height),
      to: const Rect.fromLTWH(0, 0, ThemeFooter.width, ThemeFooter.height),
    );
    // footer.h:68 blits the whole tips-bar-bg image (no crop) at (0,0).
    canvas.drawImageTopLeft(bgFooter, Offset.zero);

    var offsetX = 20.0;

    if (buttonAIcon != null) {
      canvas.drawImageTopLeft(buttonAIcon, Offset(offsetX, _buttonCenterY - buttonAIcon!.height / 2));
      offsetX += buttonAIcon!.width + _spacer;
    }

    if (hintLabelA != null && hintLabelA!.isNotEmpty) {
      final label =
          OnionCanvasOps.layoutOnionText(hintLabelA!, style: _footerStyle(hintStyle.color), fontFamily: hintFontFamily);
      label.paint(canvas, Offset(offsetX, _labelCenterY - label.height / 2));
      offsetX += label.width + _labelGap;
    }

    if (showButtonB) {
      if (buttonBIcon != null) {
        canvas.drawImageTopLeft(buttonBIcon, Offset(offsetX, _buttonCenterY - buttonBIcon!.height / 2));
        offsetX += buttonBIcon!.width + _spacer;
      }
      if (hintLabelB != null && hintLabelB!.isNotEmpty) {
        final label = OnionCanvasOps.layoutOnionText(hintLabelB!,
            style: _footerStyle(hintStyle.color), fontFamily: hintFontFamily);
        label.paint(canvas, Offset(offsetX, _labelCenterY - label.height / 2));
      }
    }

    if (totalPages != null) {
      final total = totalPages!;
      final current = total == 0 ? 0 : (currentPage ?? 0);

      final totalStyle = _footerStyle(totalColor);
      final currentStyle = _footerStyle(currentPageColor);

      final totalPainter = OnionCanvasOps.layoutOnionText('$total', style: totalStyle, fontFamily: hintFontFamily);
      final totalX = _counterRightEdge - totalPainter.width;
      totalPainter.paint(canvas, Offset(totalX, _labelCenterY - totalPainter.height / 2));

      final currentPainter = OnionCanvasOps.layoutOnionText('$current/', style: currentStyle, fontFamily: hintFontFamily);
      currentPainter.paint(canvas, Offset(totalX - currentPainter.width, _labelCenterY - currentPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeFooterPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.bgFooter != bgFooter ||
        oldDelegate.hintLabelA != hintLabelA ||
        oldDelegate.hintLabelB != hintLabelB ||
        oldDelegate.showButtonB != showButtonB ||
        oldDelegate.currentPage != currentPage ||
        oldDelegate.totalPages != totalPages;
  }
}
