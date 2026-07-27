import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/asset_resolver.dart';
import '../../core/theme_config.dart';
import 'battery_indicator.dart';
import 'onion_canvas.dart';

/// The boot/shutdown/low-battery splash — one widget for all of them,
/// mirroring `theme_renderBootScreen`
/// (`Onion/src/common/theme/render/bootScreen.h`), which the firmware
/// likewise calls once with a different [background] per variant
/// (`bootScreen.c:35-53`):
///
/// | argv | background | version | battery |
/// |---|---|---|---|
/// | `Boot` | `extra/bootScreen` | yes | **no** |
/// | `End` | `extra/Screen_Off` | yes | yes |
/// | `End_Save` | `extra/Screen_Off_Save` | yes | yes |
/// | `lowBat` | `extra/lowBat` | no | only if the asset is missing |
///
/// The background is blitted at (0,0) with no crop (`SDL_BlitSurface(bg,
/// NULL, screen, NULL)`), the version sits at `(20, 450)` and the message
/// is right-aligned to `x=620`, both in the 18px hint font the firmware
/// hardcodes here (not `hint.size`) colored with `total.color`.
class BootStyleScreen extends StatelessWidget {
  const BootStyleScreen({
    super.key,
    this.background,
    this.version = '',
    this.message = '',
    required this.hintFontFamily,
    required this.color,
    this.batteryIcon,
    this.batteryPercentage = 0,
    this.charging = false,
    this.batteryStyle,
    this.batteryFontFamily = '',
  });

  final ui.Image? background;
  final String version;
  final String message;
  final String hintFontFamily;
  final Color color;

  /// A null [batteryStyle] means "this variant doesn't show the battery"
  /// (the firmware's `show_battery`/`battery_percentage < 0`).
  final ui.Image? batteryIcon;
  final int batteryPercentage;
  final bool charging;
  final OnionBatteryPercentage? batteryStyle;
  final String batteryFontFamily;

  @override
  Widget build(BuildContext context) {
    final style = batteryStyle;
    return SizedBox(
      width: 640,
      height: 480,
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BootStylePainter(
                  background: background,
                  version: version,
                  message: message,
                  hintFontFamily: hintFontFamily,
                  color: color,
                ),
              ),
            ),
            if (style != null)
              Positioned(
                left: 596,
                top: 30,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: BatteryIndicator(
                    icon: batteryIcon,
                    percentage: batteryPercentage,
                    charging: charging,
                    style: style,
                    fontFamily: batteryFontFamily,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BootStylePainter extends CustomPainter {
  const _BootStylePainter({
    required this.background,
    required this.version,
    required this.message,
    required this.hintFontFamily,
    required this.color,
  });

  final ui.Image? background;
  final String version;
  final String message;
  final String hintFontFamily;
  final Color color;

  /// `theme_loadFont(..., 18 * g_scale)` — not `hint.size`.
  static const int _textSize = 18;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageTopLeft(background, Offset.zero);

    final style = OnionFontStyle(font: '', size: _textSize, color: color);

    if (version.isNotEmpty) {
      final painter = OnionCanvasOps.layoutOnionText(version, style: style, fontFamily: hintFontFamily);
      painter.paint(canvas, Offset(20, 450 - painter.height / 2));
    }

    if (message.isNotEmpty) {
      final painter = OnionCanvasOps.layoutOnionText(message, style: style, fontFamily: hintFontFamily);
      painter.paint(canvas, Offset(620 - painter.width, 450 - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BootStylePainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.version != version ||
        oldDelegate.message != message ||
        oldDelegate.color != color;
  }
}

/// The version string the preview shows in place of the device's
/// `/mnt/SDCARD/.tmp_update/onionVersion/version.txt`.
const String kPreviewVersionString = 'v0.0.0-preview';

/// Picks the splash background for a shutdown, with or without a pending
/// save (`bootScreen.c:39-46`).
ThemeAsset shutdownAssetFor({required bool saving}) =>
    saving ? ThemeAsset.screenOffSave : ThemeAsset.screenOff;
