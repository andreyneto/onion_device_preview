import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';

/// The shutdown screen — `extra/Screen_Off`, full screen, no chrome.
/// Any button returns to the main menu (a real device would just power
/// off here, so there's nothing to mirror for that interaction).
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
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: RawImage(image: widget.ctx.image(ThemeAsset.screenOff), filterQuality: FilterQuality.none),
      ),
    );
  }
}
