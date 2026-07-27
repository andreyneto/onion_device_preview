import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';

/// The charging animation — a theme-variable-length sequence of
/// `extra/chargingState0.png`, `chargingState1.png`, … (stopping at the
/// first missing index, capped at [_kMaxFrames] as a sanity limit),
/// paced by `extra/chargingState.json`'s `frame_delay` (milliseconds;
/// values over 10000 are treated as microseconds per the plan's spec,
/// clamped to a 15ms minimum). Neither asset is part of the fixed
/// [ThemeAsset] set — the frame count isn't known ahead of time — so
/// this screen resolves them itself via [AssetResolver.resolveImageAt]
/// rather than through the shared [ThemeRenderContext].
class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  static const _kMaxFrames = 60;

  /// `min_delay` (`chargingState.c:105`): the floor on `frame_delay`, and
  /// also the firmware loop's own `msleep`, so it doubles as the fastest
  /// the animation can possibly run.
  static const _kMinDelayMs = 15;

  List<ui.Image> _frames = const [];
  int _frameIndex = 0;
  Timer? _timer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.charging, onConfirm: _dismiss);
    _load();
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.charging);
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() => widget.controller.goBack();

  Future<void> _load() async {
    final resolver = AssetResolver(widget.controller.theme);
    final frames = <ui.Image>[];
    for (var i = 0; i < _kMaxFrames; i++) {
      final image = await resolver.resolveImageAt('skin/extra/chargingState$i.png');
      if (image == null) break;
      frames.add(image);
    }

    var frameDelayMs = 80;
    final jsonBytes = await resolver.resolveBytesAt('skin/extra/chargingState.json');
    if (jsonBytes != null) {
      try {
        final decoded = jsonDecode(utf8.decode(jsonBytes));
        if (decoded is Map && decoded['frame_delay'] is num) {
          final raw = (decoded['frame_delay'] as num).toInt();
          // `value >= 10000 ? value / 1000 : value`, integer division
          // (chargingState.c:130-131) — 10000 itself is microseconds.
          frameDelayMs = raw >= 10000 ? raw ~/ 1000 : raw;
          if (frameDelayMs < _kMinDelayMs) frameDelayMs = _kMinDelayMs;
        }
      } catch (_) {
        // Malformed sidecar: fall back to the default delay.
      }
    }

    if (!mounted) return;
    setState(() {
      _frames = frames;
      _loaded = true;
    });

    if (frames.length > 1) {
      _timer = Timer.periodic(Duration(milliseconds: frameDelayMs), (_) {
        if (!mounted) return;
        setState(() => _frameIndex = (_frameIndex + 1) % _frames.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: !_loaded || _frames.isEmpty
            ? const SizedBox.shrink()
            : RawImage(image: _frames[_frameIndex], filterQuality: FilterQuality.none),
      ),
    );
  }
}
