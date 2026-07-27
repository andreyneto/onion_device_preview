import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader, rootBundle;

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
  // HelveticaNeue-Bold, per the font's own name table. The most referenced
  // system font in the real theme repo (23 of 202 themes) — before it was
  // bundled, all of them silently rendered in italic Exo 2.
  'HENB.TTF': 'packages/onion_device_preview/Helvetica Neue Bold',
};

/// System fonts bundled as plain *assets* rather than declared under the
/// package's pubspec `fonts:` key, and therefore registered on first use
/// by [OnionFontResolver] instead of at app startup.
///
/// `wqy-microhei.ttc` is 5.2 MB — the CJK sans that stock Silky (and 23 of
/// the 202 real themes) uses for list text. Eager registration would make
/// every consumer pay that download to render a theme that may never ask
/// for it; lazy registration means only wqy themes do.
const Map<String, String> kLazySystemFontAssets = {
  'wqy-microhei.ttc': 'packages/onion_device_preview/assets/default_skin/fonts/wqy-microhei.ttc',
};

/// The family every unresolvable font path falls back to: a non-CJK
/// system font the firmware itself falls back to (`FALLBACK_FONT`,
/// `load.h:13`), always available since it ships with this package.
const String kOnionFallbackFontFamily = 'packages/onion_device_preview/Exo 2 Bold Italic';

/// Last-resort family for the CJK sans fonts (`wqy-microhei.ttc` is stock
/// Silky's list font) when the real face can't be registered — an upright
/// grotesque is visually far closer to them than the italic Exo 2, and
/// Flutter ships Roboto on every platform.
///
/// This used to be the *only* outcome for a `.ttc`, on the belief that
/// Flutter's font loader can't parse TrueType Collections. That belief was
/// wrong: [FontLoader] registers `wqy-microhei.ttc` without error and lays
/// text out with its glyphs. The fallback now only covers a genuine load
/// failure (a renderer that does reject the container, say).
const String kOnionTtcFallbackFontFamily = 'Roboto';

/// Resolves a `config.json` font path (from `title.font`, `hint.font`,
/// etc.) to a usable Flutter font family name, loading the theme's own
/// font file via [FontLoader] when needed. See `plan.md` §5-F3/T1.7.
///
/// - An absolute path (`/mnt/SDCARD/...`) is a *system* font the firmware
///   itself provides — mapped to a bundled equivalent by filename: either
///   a family declared in this package's pubspec
///   ([kBundledSystemFontFamilies]) or one registered on first use from
///   the asset bundle ([kLazySystemFontAssets]). Falls back only for
///   system fonts this package doesn't ship.
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

    if (configFontPath.startsWith('/')) {
      final basename = configFontPath.split('/').last;
      final declared = kBundledSystemFontFamilies[basename];
      if (declared != null) return declared;

      if (kLazySystemFontAssets.containsKey(basename)) {
        final family = await _lazySystemFamily(basename);
        if (family == kOnionTtcFallbackFontFamily) _failed.add(configFontPath);
        return family;
      }

      _failed.add(configFontPath);
      return kOnionFallbackFontFamily;
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

  /// Registers a [kLazySystemFontAssets] entry on first use, then hands
  /// out the same family to every later caller.
  ///
  /// The cache is static because the bytes are the package's, not a
  /// theme's: two resolvers asking for `wqy-microhei.ttc` want the very
  /// same face, and registering a 5.2 MB font twice would be wasteful.
  /// A failure is cached too — a renderer that rejects the file once will
  /// reject it every time, and retrying per theme load would stall the
  /// preview repeatedly.
  static Future<String> _lazySystemFamily(String basename) {
    return _lazySystemFamilies.putIfAbsent(basename, () async {
      try {
        final data = await rootBundle.load(kLazySystemFontAssets[basename]!);
        final family = 'onion-system-$basename';
        await (FontLoader(family)..addFont(Future.value(data))).load();
        return family;
      } catch (_) {
        return kOnionTtcFallbackFontFamily;
      }
    });
  }

  static final Map<String, Future<String>> _lazySystemFamilies = {};

  static Future<ByteData> _asFontData(Uint8List bytes) async {
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }
}
