import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/boot_style_screen.dart';

/// The boot splash: `extra/bootScreen` full-screen with the version and a
/// status message, and — unlike every other screen — **no battery**
/// (`bootScreen.c:36` passes `show_battery = false` for `Boot`; the
/// renderer skips it for a negative percentage). Layout lives in
/// [BootStyleScreen], shared with the shutdown splash exactly like the
/// firmware shares `theme_renderBootScreen`.
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
    return BootStyleScreen(
      background: widget.ctx.image(ThemeAsset.bootScreen),
      version: kPreviewVersionString,
      // The runtime passes progress messages here ("Turning on Wi-Fi...",
      // "Syncing time..." — `script/network/update_networking.sh`).
      message: 'Starting up…',
      hintFontFamily: widget.ctx.fontFamily(config.hint.font),
      color: config.total.color,
    );
  }
}
