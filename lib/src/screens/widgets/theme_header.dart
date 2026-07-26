import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import '../../device/device_state.dart' show OnionWifiState;
import 'onion_canvas.dart';

/// The 640x60 header strip: background + `bg-title` overlay, the logo,
/// a centered title, and the top-bar status indicators.
///
/// Background/logo/title mirror `theme_renderHeader`
/// (`Onion/src/common/theme/render/header.h:34-55`). The battery and
/// wifi indicators are NOT skin assets: the real MainUI draws its own
/// vertical battery pill and wifi fan internally (confirmed against
/// device screenshots MainUI_004..012 — the skin's `power-*%-icon`/
/// `icon-wifi-*` files are used elsewhere). Both are replicated here as
/// vector drawings at the measured coordinates; only the percentage
/// text honors the theme (`batteryPercentage` color/visibility/offsets).
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
    this.batteryPercentage = 100,
    this.charging = false,
    this.batteryStyle = const OnionBatteryPercentage(),
    required this.batteryFontFamily,
    this.wifi = OnionWifiState.off,
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
  final int batteryPercentage;
  final bool charging;
  final OnionBatteryPercentage batteryStyle;
  final String batteryFontFamily;
  final OnionWifiState wifi;

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
          batteryPercentage: batteryPercentage,
          charging: charging,
          batteryStyle: batteryStyle,
          batteryFontFamily: batteryFontFamily,
          wifi: wifi,
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
    required this.batteryPercentage,
    required this.charging,
    required this.batteryStyle,
    required this.batteryFontFamily,
    required this.wifi,
  });

  final ui.Image? background;
  final ui.Image? bgTitle;
  final ui.Image? logo;
  final String? title;
  final OnionFontStyle titleStyle;
  final String titleFontFamily;
  final int batteryPercentage;
  final bool charging;
  final OnionBatteryPercentage batteryStyle;
  final String batteryFontFamily;
  final OnionWifiState wifi;

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

    _paintWifi(canvas);
    _paintBattery(canvas);
  }

  // --- Battery pill [MEAS-device, MainUI_012] ---
  //
  // Vertical pill: cap (556..565 x 13..16) over a 16x30 outlined body
  // (553..568 x 16..46), inner fill 8px wide rising with the charge.
  // Percentage text starts at x=579, vertically centered on y=30.

  static const _pillBody = Rect.fromLTRB(553, 16, 569, 46);
  static const _pillCap = Rect.fromLTRB(556.5, 13, 565.5, 17);
  static const _fillMax = Rect.fromLTRB(557, 19.5, 565, 43.5);
  static const _textLeft = 579.0;
  static const _textCenterY = 30.0;
  static const _defaultTextSize = 18;

  void _paintBattery(Canvas canvas) {
    final white = Paint()..color = const Color(0xFFFFFFFF);

    canvas.drawRRect(RRect.fromRectAndRadius(_pillCap, const Radius.circular(1.5)), white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(_pillBody, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final level = (charging ? 100 : batteryPercentage).clamp(0, 100) / 100;
    if (level > 0) {
      final fillHeight = _fillMax.height * level;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(_fillMax.left, _fillMax.bottom - fillHeight, _fillMax.right, _fillMax.bottom),
          const Radius.circular(1.5),
        ),
        white,
      );
    }

    if (!batteryStyle.visible) return;
    final style = OnionFontStyle(
      font: batteryStyle.font,
      // MainUI's top bar draws the percentage at ~18px unless the theme
      // explicitly sizes it; the config default of 24 belongs to the
      // apps-side battery composite (battery.h), not this bar.
      size: batteryStyle.sizeExplicit ? batteryStyle.size : _defaultTextSize,
      color: batteryStyle.color,
    );
    final painter = OnionCanvasOps.layoutOnionText('$batteryPercentage%', style: style, fontFamily: batteryFontFamily);
    var offsetY = batteryStyle.offsetY.toDouble();
    if (batteryFontFamily.contains('Exo 2')) {
      // Same optical correction the firmware applies (battery.h:34-36).
      offsetY -= 0.075 * painter.height;
    }
    painter.paint(
      canvas,
      Offset(_textLeft + batteryStyle.offsetX.toDouble(), _textCenterY - painter.height / 2 + offsetY),
    );
  }

  // --- Wifi fan [MEAS-device, MainUI_012] ---
  //
  // Dot centered at (521, 38.5) with three 90°-sweep arcs above it
  // (~6.5px apart); lit elements are white, unlit ones a faint gray.
  // Dot + 3 arcs = 4 elements, one per signal level: signalN lights the
  // dot plus N-1 arcs (the device's weak-signal shot shows dot + the
  // smallest arc). `locked` (no open reference) shows the dim fan with
  // only the dot lit.

  static const _wifiDot = Offset(521, 38.5);
  static const _wifiArcRadii = <double>[9.5, 16, 22.5];
  static const _litColor = Color(0xFFFFFFFF);
  static const _dimColor = Color(0x40FFFFFF);

  void _paintWifi(Canvas canvas) {
    if (wifi == OnionWifiState.off) return;

    final litArcs = switch (wifi) {
      OnionWifiState.off || OnionWifiState.locked => 0,
      OnionWifiState.signal1 => 0,
      OnionWifiState.signal2 => 1,
      OnionWifiState.signal3 => 2,
      OnionWifiState.signal4 => 3,
    };

    canvas.drawCircle(_wifiDot, 3.2, Paint()..color = _litColor);

    for (var i = 0; i < _wifiArcRadii.length; i++) {
      final paint = Paint()
        ..color = i < litArcs ? _litColor : _dimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      // 90° sweep opening upward: from 225° to 315° in canvas angles.
      canvas.drawArc(
        Rect.fromCircle(center: _wifiDot, radius: _wifiArcRadii[i]),
        -3 * 3.1415926535 / 4,
        3.1415926535 / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeHeaderPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.bgTitle != bgTitle ||
        oldDelegate.logo != logo ||
        oldDelegate.title != title ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.batteryPercentage != batteryPercentage ||
        oldDelegate.charging != charging ||
        oldDelegate.wifi != wifi;
  }
}
