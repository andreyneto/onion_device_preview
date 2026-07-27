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
/// (`chargingState.c:106`) — and the floor this preview actually uses;
/// see [chargingFrameDelayMs].
const int kChargingDefaultDelayMs = 80;

/// Frame delay in milliseconds for a `chargingState.json` `frame_delay` of
/// [raw] (null when there's no sidecar or it doesn't parse).
///
/// Follows `chargingState.c:126-137` — values of 10000 or more are
/// microseconds, integer-divided — with one **deliberate deviation**: the
/// floor is [kChargingDefaultDelayMs], not the firmware's
/// [kChargingMinDelayMs].
///
/// Why: the stock sidecar asks for 15ms, but 15ms is just the loop's
/// `msleep` — on the device each frame also costs a 640x480x32 blit plus
/// an `SDL_Flip` on the Miyoo framebuffer, so the hardware never gets
/// near 66fps and the real animation is visibly slower than a literal
/// 15ms replay (confirmed by the user against their Mini+). 80ms is the
/// firmware's own default when a theme ships frames without a sidecar,
/// and the most common value among the themes that do ship one (25 of 67
/// in the `Themes` repo), so it's the closest thing to an authored
/// "intended" pace.
int chargingFrameDelayMs(int? raw) {
  if (raw == null) return kChargingDefaultDelayMs;
  final ms = raw >= 10000 ? raw ~/ 1000 : raw;
  return ms < kChargingDefaultDelayMs ? kChargingDefaultDelayMs : ms;
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
