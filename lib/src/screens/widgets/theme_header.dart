import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import 'onion_canvas.dart';

/// The 640x60 header strip: background + `bg-title` overlay, the logo,
/// and a centered title — mirrors `theme_renderHeader`
/// (`Onion/src/common/theme/render/header.h:34-55`).
///
/// The battery/wifi indicators are NOT part of this strip: MainUI draws
/// them last, above everything (including overlays), and a theme's icon
/// canvas may deliberately spill outside the header — see
/// `StatusIndicators`, painted at the top of the screen's layer stack.
class ThemeHeader extends StatelessWidget {
  const ThemeHeader({
    super.key,
    required this.background,
    required this.bgTitle,
    this.logo,
    this.showLogo = true,
    this.title,
    required this.titleStyle,
    required this.titleFontFamily,
  });

  static const double height = 60;
  static const double width = 640;

  final ui.Image? background;
  final ui.Image? bgTitle;
  final ui.Image? logo;
  final bool showLogo;
  final String? title;
  final OnionFontStyle titleStyle;
  final String titleFontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ThemeHeaderPainter(
          background: background,
          bgTitle: bgTitle,
          logo: showLogo ? logo : null,
          title: title,
          titleStyle: titleStyle,
          titleFontFamily: titleFontFamily,
        ),
      ),
    );
  }
}

class _ThemeHeaderPainter extends CustomPainter {
  const _ThemeHeaderPainter({
    required this.background,
    required this.bgTitle,
    required this.logo,
    required this.title,
    required this.titleStyle,
    required this.titleFontFamily,
  });

  final ui.Image? background;
  final ui.Image? bgTitle;
  final ui.Image? logo;
  final String? title;
  final OnionFontStyle titleStyle;
  final String titleFontFamily;

  static const _headerRect = Rect.fromLTWH(0, 0, ThemeHeader.width, ThemeHeader.height);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRegion(background, from: _headerRect, to: _headerRect);
    canvas.drawImageRegion(bgTitle, from: _headerRect, to: _headerRect);

    // header.h:40 — logo at fixed x=20, vertically centered at y=30.
    if (logo != null) {
      canvas.drawImageTopLeft(logo, Offset(20, 30 - logo!.height / 2));
    }

    // header.h:47 — title horizontally centered, vertically centered at y=29.
    if (title != null && title!.isNotEmpty) {
      final painter = OnionCanvasOps.layoutOnionText(title!, style: titleStyle, fontFamily: titleFontFamily);
      painter.paint(canvas, Offset((ThemeHeader.width - painter.width) / 2, 29 - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeHeaderPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.bgTitle != bgTitle ||
        oldDelegate.logo != logo ||
        oldDelegate.title != title ||
        oldDelegate.titleStyle != titleStyle;
  }
}
