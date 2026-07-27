import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/boot_style_screen.dart';

/// The shutdown splash: `extra/Screen_Off` (or `extra/Screen_Off_Save`
/// when a game's state is being saved on the way out — the runtime's
/// `check_off_order "End"` vs `"End_Save"`), the version string, and the
/// battery, which this variant *does* show (`bootScreen.c:39-46` sets
/// `show_battery = true` for both End variants). No message: the runtime
/// calls `bootScreen "End"` with no second argument.
///
/// Any button returns to the main menu — a real device would power off
/// here, so there's nothing to mirror for that interaction.
class ShutdownScreen extends StatefulWidget {
  const ShutdownScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<ShutdownScreen> createState() => _ShutdownScreenState();
}

class _ShutdownScreenState extends State<ShutdownScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.shutdown, onConfirm: _dismiss, onCancel: _dismiss);
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.shutdown);
    super.dispose();
  }

  void _dismiss() => widget.controller.resetTo(OnionScreenKind.mainMenu);

  @override
  Widget build(BuildContext context) {
    final config = widget.ctx.config;
    final controller = widget.controller;
    return BootStyleScreen(
      background: widget.ctx.image(shutdownAssetFor(saving: controller.shutdownSaving)),
      version: kPreviewVersionString,
      hintFontFamily: widget.ctx.fontFamily(config.hint.font),
      color: config.total.color,
      batteryIcon: widget.ctx.image(batteryAssetFor(controller.batteryPercent, charging: controller.charging)),
      batteryPercentage: controller.batteryPercent,
      charging: controller.charging,
      batteryStyle: config.batteryPercentage,
      batteryFontFamily: widget.ctx.fontFamily(config.batteryPercentage.font),
    );
  }
}
