import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';

/// The charging animation — a theme-variable-length sequence of
/// `extra/chargingState0.png`, `chargingState1.png`, … (stopping at the
/// first missing index, capped at [_kMaxFrames] as a sanity limit), paced
/// by `extra/chargingState.json`'s `frame_delay` (see
/// [chargingFrameDelayMs]). Neither asset is part of the fixed
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

/// The firmware's own floor on `frame_delay` (`min_delay`,
/// `chargingState.c:105`), which is also the charging loop's `msleep`.
const int kChargingMinDelayMs = 15;

/// `frame_delay` when the sidecar is missing or unreadable
/// (`chargingState.c:106`).
const int kChargingDefaultDelayMs = 80;

/// The fastest frame period the device actually achieves — [MEAS-device]:
/// the stock 24-frame animation (nominal `frame_delay` 15) measured at
/// 2.28s per cycle averaged over 5 cycles on a Mini+ → 95ms/frame. This
/// is the loop's real per-frame cost (a 640x480x32 blit + `SDL_Flip` on
/// the Miyoo framebuffer, plus the 15ms `msleep`), which caps the rate
/// regardless of what the sidecar asks for.
const int kChargingDeviceFloorMs = 95;

/// Frame delay in milliseconds for a `chargingState.json` `frame_delay` of
/// [raw] (null when there's no sidecar or it doesn't parse).
///
/// Follows `chargingState.c:126-137` — values of 10000 or more are
/// microseconds, integer-divided — then applies the device's measured
/// floor: the firmware loop renders as fast as it can once `frame_delay`
/// falls below its real per-frame cost, so the effective period on
/// hardware is `max(frame_delay, ~95ms)` ([kChargingDeviceFloorMs]).
/// Themes asking for slower paces (500ms etc.) are honored as authored.
int chargingFrameDelayMs(int? raw) {
  final ms = raw == null ? kChargingDefaultDelayMs : (raw >= 10000 ? raw ~/ 1000 : raw);
  return ms < kChargingDeviceFloorMs ? kChargingDeviceFloorMs : ms;
}

class _ChargingScreenState extends State<ChargingScreen> {
  static const _kMaxFrames = 60;

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

    int? rawDelay;
    final jsonBytes = await resolver.resolveBytesAt('skin/extra/chargingState.json');
    if (jsonBytes != null) {
      try {
        final decoded = jsonDecode(utf8.decode(jsonBytes));
        if (decoded is Map && decoded['frame_delay'] is num) {
          rawDelay = (decoded['frame_delay'] as num).toInt();
        }
      } catch (_) {
        // Malformed sidecar: fall back to the default delay.
      }
    }
    final frameDelayMs = chargingFrameDelayMs(rawDelay);

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
