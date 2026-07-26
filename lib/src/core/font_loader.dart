import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

import 'theme_bundle.dart';

/// Font family names for the fonts bundled in `assets/default_skin/fonts/`
/// and declared in this package's `pubspec.yaml` (so they're registered
/// automatically at app startup — no dynamic [FontLoader] needed for
/// these). Keyed by the firmware's system font filename
/// (`Onion/static/build/miyoo/app/*.ttf`), so a `config.json` font path
/// like `/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic.ttf` can be mapped back
/// to the family that ships with this package.
///
/// Families carry the `packages/onion_device_preview/` prefix because
/// that's how Flutter namespaces fonts declared in a *package's*
/// pubspec: a consuming app only resolves them under the prefixed name
/// (using the bare family silently falls back to the default typeface —
/// upright Roboto instead of the italic Exo 2).
///
/// `Exo-2-Bold-Italic_Universal.ttf` (the extended-coverage variant the
/// stock "Silky" config actually references) maps to the same bundled
/// base file — identical glyphs for the Latin range a preview renders.
const Map<String, String> kBundledSystemFontFamilies = {
  'Exo-2-Bold-Italic.ttf': 'packages/onion_device_preview/Exo 2 Bold Italic',
  'Exo-2-Bold-Italic_Universal.ttf': 'packages/onion_device_preview/Exo 2 Bold Italic',
  'BPreplayBold.otf': 'packages/onion_device_preview/BPreplay Bold',
  'Helvetica-Neue-2.ttf': 'packages/onion_device_preview/Helvetica Neue 2',
};

/// The family every unresolvable font path falls back to: a non-CJK
/// system font the firmware itself falls back to (`FALLBACK_FONT`,
/// `load.h:13`), always available since it ships with this package.
const String kOnionFallbackFontFamily = 'packages/onion_device_preview/Exo 2 Bold Italic';

/// Fallback for `.ttc` fonts specifically (Flutter can't load TrueType
/// Collections). These are the CJK sans fonts (`wqy-microhei.ttc` is
/// stock Silky's list font) that the *device* renders fine — an upright
/// grotesque like Roboto is visually far closer to them than the italic
/// Exo 2, and Flutter ships it on every platform.
const String kOnionTtcFallbackFontFamily = 'Roboto';

/// Resolves a `config.json` font path (from `title.font`, `hint.font`,
/// etc.) to a usable Flutter font family name, loading the theme's own
/// font file via [FontLoader] when needed. See `plan.md` §5-F3/T1.7.
///
/// - An absolute path (`/mnt/SDCARD/...`) is a *system* font the firmware
///   itself provides — mapped to a bundled equivalent by filename, or to
///   the fallback family if this package doesn't ship that one.
/// - A `.ttc` (TrueType Collection) can't be parsed by Flutter's font
///   loader, so it always falls back.
/// - Anything else is a relative path to a font file the theme ships in
///   its own zip; its bytes are registered under a family name unique to
///   this resolver instance, so two themes loading fonts of the same
///   filename never collide.
class OnionFontResolver {
  OnionFontResolver(this.bundle, {String? instanceId}) : _instanceId = instanceId ?? identityHashCode(bundle).toString();

  final OnionThemeBundle bundle;
  final String _instanceId;

  final Map<String, String> _resolved = {};
  final Set<String> _failed = {};

  /// Font paths that fell back to [kOnionFallbackFontFamily] because they
  /// couldn't be loaded (missing from the zip, `.ttc`, or a decode error).
  Set<String> get failed => Set.unmodifiable(_failed);

  Future<String> resolveFamily(String configFontPath) async {
    final cached = _resolved[configFontPath];
    if (cached != null) return cached;

    final family = await _resolve(configFontPath);
    _resolved[configFontPath] = family;
    return family;
  }

  Future<String> _resolve(String configFontPath) async {
    if (configFontPath.isEmpty) return kOnionFallbackFontFamily;

    // Checked before the absolute-path branch: system fonts can be .ttc
    // too (stock Silky's list font is /mnt/SDCARD/.../wqy-microhei.ttc).
    if (configFontPath.toLowerCase().endsWith('.ttc')) {
      _failed.add(configFontPath);
      return kOnionTtcFallbackFontFamily;
    }

    if (configFontPath.startsWith('/')) {
      final basename = configFontPath.split('/').last;
      return kBundledSystemFontFamilies[basename] ?? kOnionFallbackFontFamily;
    }

    final bytes = bundle[configFontPath];
    if (bytes == null) {
      _failed.add(configFontPath);
      return kOnionFallbackFontFamily;
    }

    final family = 'onion-theme-$_instanceId-$configFontPath';
    try {
      final loader = FontLoader(family)..addFont(_asFontData(bytes));
      await loader.load();
      return family;
    } catch (_) {
      _failed.add(configFontPath);
      return kOnionFallbackFontFamily;
    }
  }

  static Future<ByteData> _asFontData(Uint8List bytes) async {
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }
}
