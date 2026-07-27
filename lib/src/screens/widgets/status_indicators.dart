import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme_config.dart';
import 'onion_canvas.dart';

/// The top-bar status indicators — battery icon + percentage and wifi —
/// painted over the *whole* 640x480 screen, above every other layer
/// (chrome, overlays, even the pop menu's scrim), which is how MainUI
/// draws them (MainUI_008: they stay full-bright over the dimmed list).
///
/// Both are theme assets blitted with their whole canvas centered on
/// fixed anchors ([MEAS-device], MainUI_012 — wifi matched
/// `icon-wifi-signal-03` with MSE 0.0):
///
///   battery  `power-*%-icon` canvas centered at (596, 30) — themes
///            position the drawing *inside* the canvas to place it
///            (stock Silky's 88x48 canvas holds a 16x34 pill on its
///            left edge; win98 uses a 982x900 canvas to park the icon
///            down in its taskbar, spilling far outside the header)
///   text     the percentage centered at (596, 30) ON TOP of the icon
///            canvas (Blueprint/Silky design around that), ~18px unless
///            the theme sets `batteryPercentage.size`; hidden while
///            charging (battery.h:28-29)
///   wifi     `icon-wifi-*` canvas centered at (528, 30)
class StatusIndicators extends StatelessWidget {
  const StatusIndicators({
    super.key,
    this.batteryIcon,
    required this.batteryPercentage,
    required this.charging,
    required this.batteryStyle,
    required this.batteryFontFamily,
    this.wifiIcon,
    this.batteryCenter = _defaultBatteryCenter,
  });

  /// `theme_renderHeaderBattery` (`render/header.h:19`).
  static const Offset _defaultBatteryCenter = Offset(596, 30);

  final ui.Image? batteryIcon;
  final int batteryPercentage;
  final bool charging;
  final OnionBatteryPercentage batteryStyle;
  final String batteryFontFamily;
  final ui.Image? wifiIcon;

  /// Where the battery icon's canvas is centered. Defaults to the standard
  /// header's (596, 30); the Game Switcher recenters it on a custom
  /// `gs-top-bar`'s own height (`theme_renderHeaderBatteryCustom`).
  final Offset batteryCenter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(640, 480),
        painter: _StatusIndicatorsPainter(
          batteryIcon: batteryIcon,
          batteryPercentage: batteryPercentage,
          charging: charging,
          batteryStyle: batteryStyle,
          batteryFontFamily: batteryFontFamily,
          wifiIcon: wifiIcon,
          batteryCenter: batteryCenter,
        ),
      ),
    );
  }
}

class _StatusIndicatorsPainter extends CustomPainter {
  const _StatusIndicatorsPainter({
    required this.batteryIcon,
    required this.batteryPercentage,
    required this.charging,
    required this.batteryStyle,
    required this.batteryFontFamily,
    required this.wifiIcon,
    required this.batteryCenter,
  });

  final ui.Image? batteryIcon;
  final int batteryPercentage;
  final bool charging;
  final OnionBatteryPercentage batteryStyle;
  final String batteryFontFamily;
  final ui.Image? wifiIcon;
  final Offset batteryCenter;

  static const _wifiCenter = Offset(528, 30);
  static const _defaultTextSize = 18;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 640, 480));
    canvas.drawImageCentered(wifiIcon, _wifiCenter);
    canvas.drawImageCentered(batteryIcon, batteryCenter);
    canvas.restore();

    // "Currently charging, hide text" (battery.h:28-29).
    if (!batteryStyle.visible || charging) return;

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
      Offset(
        batteryCenter.dx - painter.width / 2 + batteryStyle.offsetX,
        batteryCenter.dy - painter.height / 2 + offsetY,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _StatusIndicatorsPainter oldDelegate) {
    return oldDelegate.batteryIcon != batteryIcon ||
        oldDelegate.batteryCenter != batteryCenter ||
        oldDelegate.batteryPercentage != batteryPercentage ||
        oldDelegate.charging != charging ||
        oldDelegate.wifiIcon != wifiIcon ||
        oldDelegate.batteryStyle != batteryStyle;
  }
}
