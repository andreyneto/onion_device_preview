import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/asset_resolver.dart';
import '../core/theme_bundle.dart';

/// The theme's sounds: `sound/bgm.mp3` looped as background music and
/// `sound/change.wav` blipped on navigation — resolved through the same
/// theme-zip → default-skin fallback chain as the skin assets.
///
/// Created lazily by `OnionPreviewController.setSoundEnabled(true)` so
/// that merely constructing a controller (e.g. in tests) never touches
/// the audio plugin. Every playback call swallows errors: sound is a
/// nicety, and browsers' autoplay policies make failures routine.
class OnionSoundBank {
  AudioPlayer? _bgm;
  AudioPlayer? _sfx;
  Uint8List? _changeBytes;

  /// (Re-)resolves [theme]'s sounds and starts the bgm loop. Called on
  /// enable and again on every theme swap while enabled.
  Future<void> start(OnionThemeBundle theme) async {
    final resolver = AssetResolver(theme);
    final bgmBytes = await resolver.resolveBytesAt('sound/bgm.mp3');
    final changeBytes = await resolver.resolveBytesAt('sound/change.wav');
    _changeBytes = changeBytes != null && _looksLikeWav(changeBytes) ? changeBytes : null;

    try {
      await _bgm?.stop();
      // The stock firmware's own default sound/bgm.mp3 is literally a
      // placeholder PNG (silence by default; themes ship a real mp3), so
      // sniff the signature instead of trusting the extension.
      if (bgmBytes != null && _looksLikeMp3(bgmBytes)) {
        final player = _bgm ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(_source(bgmBytes, 'audio/mpeg'));
      }
    } catch (_) {
      // Autoplay blocked or codec unsupported — stay silent.
    }
  }

  /// Plays the navigation blip (restarting it if one is still sounding).
  Future<void> playChange() async {
    final bytes = _changeBytes;
    if (bytes == null) return;
    try {
      final player = _sfx ??= AudioPlayer();
      await player.stop();
      await player.play(_source(bytes, 'audio/wav'));
    } catch (_) {
      // Same tolerance as start().
    }
  }

  /// ID3 header or a bare MPEG frame-sync.
  static bool _looksLikeMp3(Uint8List b) =>
      b.length > 2 && ((b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) || (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0));

  static bool _looksLikeWav(Uint8List b) =>
      b.length > 3 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46; // 'RIFF'

  Future<void> stop() async {
    try {
      await _bgm?.stop();
      await _sfx?.stop();
    } catch (_) {}
  }

  void dispose() {
    _bgm?.dispose();
    _sfx?.dispose();
    _bgm = null;
    _sfx = null;
  }

  /// Web's audio element can't stream from raw bytes the way the native
  /// implementations can, but it happily plays a `data:` URL.
  static Source _source(Uint8List bytes, String mimeType) {
    if (kIsWeb) return UrlSource('data:$mimeType;base64,${base64Encode(bytes)}');
    return BytesSource(bytes);
  }
}
