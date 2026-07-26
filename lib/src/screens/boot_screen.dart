import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/battery_indicator.dart';
import 'widgets/onion_canvas.dart';

/// The boot splash — mirrors `theme_renderBootScreen`
/// (`Onion/src/common/theme/render/bootScreen.h`): a full-screen
/// `extra/bootScreen` background (no header/footer chrome at all, unlike
/// every other screen), a version string at `(20, 450)` and a message
/// right-aligned to `x=620`, both in the fixed 18px hint font the
/// firmware hardcodes here (not `config.hint.size`), colored with
/// `total.color`, plus the header's own battery composite at its usual
/// `(596, 30)`.
///
/// Advances to the main menu on any confirm press, or automatically
/// after 1.5s — real boot screens are timed, not interactive.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.boot, onConfirm: _advance);
    _autoAdvance = Timer(const Duration(milliseconds: 1500), _advance);
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.boot);
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _advance() {
    _autoAdvance?.cancel();
    widget.controller.resetTo(OnionScreenKind.mainMenu);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.ctx.config;
    return SizedBox(
      width: 640,
      height: 480,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BootPainter(
                background: widget.ctx.image(ThemeAsset.bootScreen),
                hintFontFamily: widget.ctx.fontFamily(config.hint.font),
                color: config.total.color,
              ),
            ),
          ),
          Positioned(
            left: 596,
            top: 30,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: BatteryIndicator(
                icon: widget.ctx.image(
                  batteryAssetFor(widget.controller.batteryPercent, charging: widget.controller.charging),
                ),
                percentage: widget.controller.batteryPercent,
                charging: widget.controller.charging,
                style: config.batteryPercentage,
                fontFamily: widget.ctx.fontFamily(config.batteryPercentage.font),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BootPainter extends CustomPainter {
  const _BootPainter({required this.background, required this.hintFontFamily, required this.color});

  final ui.Image? background;
  final String hintFontFamily;
  final Color color;

  static const _version = 'v0.0.0-preview';
  static const _message = 'Starting up…';

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageTopLeft(background, Offset.zero);

    final style = OnionFontStyle(font: '', size: 18, color: color);
    final version = OnionCanvasOps.layoutOnionText(_version, style: style, fontFamily: hintFontFamily);
    version.paint(canvas, Offset(20, 450 - version.height / 2));

    final message = OnionCanvasOps.layoutOnionText(_message, style: style, fontFamily: hintFontFamily);
    message.paint(canvas, Offset(620 - message.width, 450 - message.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BootPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.color != color;
}
